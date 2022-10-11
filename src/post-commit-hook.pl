#!/bin/perl
use strict;
use warnings;

#Get commit message of the last commit
my $commit_msg = `git show --format=%B --no-patch`;
chomp($commit_msg);

#Check if the last commit is a stash commit
if ($commit_msg =~ m/^stash!/) {
  exit
}

my $branch = `git branch --show-current`;
chomp($branch);
my @branch = split(/-/, $branch);

# Merge stash into original branch
system('git', 'switch', $branch[1]);
system('git', 'merge', '--squash', $branch);
system('git', 'commit', '-m', $commit_msg);
