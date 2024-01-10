# Copyright (c) 2008, 2011 Oracle and/or its affiliates. All rights reserved.
# Copyright (c) 2013, Monty Program Ab.
# Use is subject to license terms.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA

package GenTest::Validator::ResultsetComparatorSimplify;

require Exporter;
@ISA = qw(GenTest GenTest::Validator);

use strict;

use GenTest;
use GenTest::Constants;
use GenTest::Comparator;
use GenTest::Result;
use GenTest::Validator;
use GenTest::Executor::MySQL;
use GenTest::Simplifier::SQL;
use GenTest::Simplifier::Test;

use DBI;
use DBIx::MyParsePP;
use DBIx::MyParsePP::Rule;

my $empty_child = DBIx::MyParsePP::Rule->new();
my $myparse = DBIx::MyParsePP->new();
my $query_obj;

sub validate {
	my ($comparator, $executors, $results) = @_;

	die "ResultsetComparatorSimplify requires two resultsets" if $#$results != 1;

	if ( $results->[0]->status() ne $results->[1]->status() ) {
		say("Query: ".$results->[0]->query()."; failed: error status mismatch between servers ('".$results->[0]->errstr()."' vs. '".$results->[1]->errstr()."')");
		return STATUS_ERROR_MISMATCH;
	}

	return STATUS_WONT_HANDLE if $results->[0]->status() != STATUS_OK;
	return STATUS_WONT_HANDLE if $results->[1]->status() != STATUS_OK;

	return STATUS_WONT_HANDLE if defined $results->[0]->warnings();
	return STATUS_WONT_HANDLE if defined $results->[1]->warnings();

	my $query = $results->[0]->query();
	my $compare_outcome = GenTest::Comparator::compare($results->[0], $results->[1]);

	if ( ($compare_outcome == STATUS_LENGTH_MISMATCH) ||
	     ($compare_outcome == STATUS_CONTENT_MISMATCH) 
	) {
		say("---------- RESULT COMPARISON ISSUE START ----------");
	}

	if ($compare_outcome == STATUS_LENGTH_MISMATCH) {
		say("Query: $query; failed: result length mismatch between servers (".$results->[0]->rows()." vs. ".$results->[1]->rows().")");
		say(GenTest::Comparator::dumpDiff($results->[0], $results->[1]));
	} elsif ($compare_outcome == STATUS_CONTENT_MISMATCH) {
		say("Query: $query; failed: result content mismatch between servers.");
		say(GenTest::Comparator::dumpDiff($results->[0], $results->[1]));
	}

	if (
		($query =~ m{^\s*select|explain}sio) && (
			($compare_outcome == STATUS_LENGTH_MISMATCH) ||
			($compare_outcome == STATUS_CONTENT_MISMATCH)
		)
	) {
		my $simplifier_sql = GenTest::Simplifier::SQL->new(
			oracle => sub {
				my $oracle_query = shift;

                return ORACLE_ISSUE_NO_LONGER_REPEATABLE if (($query =~ m{ORDER\s+BY}sgio) && ($oracle_query !~ m{ORDER\s+BY}sgio));

				# Prevent the removal of * from SELECT *, as this makes the resulting query unparseable
				return ORACLE_ISSUE_NO_LONGER_REPEATABLE if (($query =~ m{\*}sgio) && ($oracle_query !~ m{\*}sgio));

				# Prevent the reduction of e.g. COUNT(a1.f1) to COUNT(a1) as this is confusing
				return ORACLE_ISSUE_NO_LONGER_REPEATABLE if $oracle_query =~ m{(MIN|MAX|AVG|COUNT)\s*\(\s*(t1|t2|t3|a1|a2|a3)\s*\)}sgio;

				foreach my $try (1..1) {

					my @oracle_results;
					foreach my $executor (@$executors) {
						my $oracle_result = $executor->execute($oracle_query, 1);

						return ORACLE_ISSUE_STATUS_UNKNOWN if $oracle_result->status() != STATUS_OK;
						return ORACLE_ISSUE_STATUS_UNKNOWN if defined $oracle_result->warnings();

						# Reject the simplification if the result set contains sets

						if (defined $oracle_result->data()) {
							foreach my $row (@{$oracle_result->data()}) {
								foreach my $col (@$row) {
									return ORACLE_ISSUE_NO_LONGER_REPEATABLE if $col =~ m{^\(}sgio;
								}
							}
						}

						push @oracle_results, $oracle_result;
					}


					my $oracle_compare = GenTest::Comparator::compare($oracle_results[0], $oracle_results[1]);

					#
					# If both result sets are empty, we can not decide if the issue continues to be repeatable
					# or not. So, to be safe, we return "unknown", otherwise we risk messing up the differential
					# coverage reports
					#

					if (($oracle_results[0]->rows() == 0) && ($oracle_results[1]->rows() == 0)) {
						return ORACLE_ISSUE_STATUS_UNKNOWN;
					}

					if (
						($oracle_compare == STATUS_LENGTH_MISMATCH) ||
						($oracle_compare == STATUS_CONTENT_MISMATCH)
					) {
						return ORACLE_ISSUE_STILL_REPEATABLE;
					}
				}

				return ORACLE_ISSUE_NO_LONGER_REPEATABLE;
		        }
		);

        say("Simplifying...");
		my $simplified_query = $simplifier_sql->simplify($query);
		
		if (defined $simplified_query) {
			say("Simplified query: $simplified_query;");

			if ($simplified_query !~ m{EXPLAIN}sgio) {
				my @explains = (
					$executors->[0]->execute("EXPLAIN ".$simplified_query),
					$executors->[1]->execute("EXPLAIN ".$simplified_query)
				);
	                	say("EXPLAIN diff:");
				say(GenTest::Comparator::dumpDiff(@explains));
			}

			my $simplified_results = [];
			$simplified_results->[0] = $executors->[0]->execute($simplified_query, 1);
			$simplified_results->[1] = $executors->[1]->execute($simplified_query, 1);
			say("Result set diff:");
			say(GenTest::Comparator::dumpDiff($simplified_results->[0], $simplified_results->[1]));


# Applies to MySQL only, so disabled here
#			my $simplifier_test = GenTest::Simplifier::Test->new(
#				executors	=> $executors,
#				results		=> [ $simplified_results , $results ]
#			);
			# show_index is enabled for result difference queries its good to see the index details,
			# the value 1 is used to define if show_index is enabled, to disable dont assign a value.
#			my $show_index = 1;
#			my $simplified_test = $simplifier_test->simplify($show_index);

#			my $tmpfile = tmpdir().abs($$).time().".test";
#			say("Dumping .test to $tmpfile");
#			open (TESTFILE, '>'.$tmpfile);
#			print TESTFILE $simplified_test;
#			close TESTFILE;
		} else {
			say("Could not simplify failure, appears to be sporadic.");
		}
	}

	if ( ($compare_outcome == STATUS_LENGTH_MISMATCH) ||
	     ($compare_outcome == STATUS_CONTENT_MISMATCH) 
	) {
		say("---------- RESULT COMPARISON ISSUE END ------------");
#               die;
	}

	#
	# If the discrepancy is found on SELECT, we reduce the severity of the error so that the test can continue
	# hopefully finding further errors in the same run or providing an indication as to how frequent the error is
	#
	# If the discrepancy is on an UPDATE, then the servers have diverged and the test can not continue safely.
	# 

        if ($query =~ m{^[\s/*!0-9]*(EXPLAIN|SELECT|ALTER|LOAD\s+INDEX|CACHE\s+INDEX)}io) {
		return $compare_outcome - STATUS_SELECT_REDUCTION;
	} else {
		return $compare_outcome;
	}
}

1;
