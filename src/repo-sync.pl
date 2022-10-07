#!/bin/perl
use strict;
use warnings;
use feature 'signatures';
use File::Find;

$, = "\n";
$\ = "\n";

my @repos = ();
my $stash_name_format = "[branch]-[name]";

# Find all repos in home
sub wanted {
  if (/^\../) {
    $File::Find::prune = 1;
    return;
  }
  if (-d && -e "$_/.git") {
    push @repos,$File::Find::name;
    $File::Find::prune = 1;
  }
}
find(\&wanted, ("/home/jakob/"));
print "Repos found:";
print @repos;

# Push every repo to remote
foreach my $repo (@repos) {
  # Check if repo has a remote
  unless (`git remote -v` =~ m/push/) {
    die "$repo has no remote to push to!"
  }

  my $commit_message = `git show --format=%s --no-patch`;
  my $branch = `git branch --show-current`;
  my $user = lc(`git config --get user.name`);
  $user =~ s/\s/-/;

  my $stash_name;

  if ($branch =~ m/^stash:$branch-$user/) {
    # If current branch is already a stash just create a new commit and push
    $stash_name = $branch;
  }
  else {
    # If current branch isn't a stash create a new one
    $stash_name = parse_stash_name($stash_name_format, $user, $branch);

    print "Creating stash for $branch...";
    system("git", "branch", $stash_name);
  }
    
  print "Creating new commit...";
  system("git", "add", "--all");
  system("git", "commit", "-m", "stash: sync current working-tree with remote") == 0 
    or die "Commit to $stash_name failed with: $?";

  print "Pushing to remote...";
  system("git", "push") == 0
    or die "Push to remote failed with: $?";
}

#Create stash name after the given format
sub parse_stash_name ($stash_name_format, $user, $branch) {
  my $stash_name = "stash:";
  $stash_name =~ s/\[name\]/$user/;
  $stash_name =~ s/\[branch\]/$branch/;
}
