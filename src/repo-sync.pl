#!/bin/perl
use strict;
use warnings;
use Env qw(HOME);
use feature 'signatures';
use File::Find;

$/ = '';

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
find(\&wanted, ("$HOME/repos"));
print "Repos found:\n";
$, = "\n";
print "@repos\n";
$, = undef;

# Push every repo to remote
foreach my $repo (@repos) {
  print "Syncing stash of $repo\n";
  chdir $repo;

  # Check if repo has a remote
  unless (`git remote -v` =~ m/push/) {
    warn "$repo has no remote to push to!"
  }
  print '\n';

  my $commit_message = `git show --format=%s --no-patch`;
  my $branch = `git branch --show-current`;
  chomp($branch);
  my $user = lc(`git config --get user.name`);
  chomp($user);
  $user =~ s/\s/-/;

  my $stash_name;

  if ($branch =~ m/stash-/) {
    # If current branch is already a stash just create a new commit and push
    $stash_name = $branch;
  }
  else {
    my $status = `git status --porcelain=v2`;
    chomp($status);
    print $status;

    if ($status eq "") {
      print "No new changes.\n";
      $stash_name = $branch;
    }
    else {
      # If current branch isn't a stash create a new one
      $stash_name = parse_stash_name($stash_name_format, $user, $branch);

      print "Creating stash $stash_name for $branch...\n";
      system("git", "switch", ,"-c", $stash_name);
    }
    print '\n';
  }
    
  print "Creating new commit...\n";
  system("git", "add", "--all");
  system("git", "commit", "-m", "stash!");
  print '\n';

  print "Pushing to remote...\n";
  system("git", "push", "--set-upstream", "origin", $stash_name);
  print '\n';
}

#Create stash name after the given format
sub parse_stash_name ($stash_name_format, $user, $branch) {
  my $stash_name = "stash-$stash_name_format";
  $stash_name =~ s/\[name\]/$user/;
  $stash_name =~ s/\[branch\]/$branch/;
  return $stash_name;
}
