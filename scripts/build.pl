#!/usr/bin/env perl

use warnings;
use strict;
use v5.10.0;
use autodie qw(:all);   # Recommended more: defaults and system/exec.

my $version = $ARGV[0];

if (not $version) {
    die 'Usage build.pl <version>';
}

if (not -f 'Dockerfile') {
    die 'No Dockerfile found';
}

if (not -e '/opt/homebrew/bin/gh') {
    die 'No gh found';
}

if (not -f 'action.yml') {
    die 'No action.yml found';
}

open my $fh, '<', 'action.yml';
my $action_yml = do { local $/; <$fh> };
if ($action_yml !~ m/docker:\/\/jonasbn\/github-action-spellcheck:$version/) {
    die "Version in action.yml does not match: $version";
}
close $fh;

say "Building Docker images for version: $version";

my @targets = qw(v0 latest);

push @targets, $version;

say 'Building Docker images for amd64 architecture';

my $counter = 0;
my $total = scalar @targets;

foreach my $target (@targets) {
    say "Building $target ($counter/$total)";
    system "docker build --platform linux/amd64 --tag jonasbn/github-action-spellcheck:$target .";
    $counter++;
}

$counter = 0;

say "Pushing Docker images to DockerHub";
foreach my $target (@targets) {
    say "Pushing $target ($counter/$total)";
    system "docker push jonasbn/github-action-spellcheck:$target";
    $counter++;
}

# Updating the v0 tag
say 'Deleting existing tag v0 locally';
say 'git tag --delete v0';
system 'git tag --delete v0';

say 'Deleting existing tag v0 remotely';
say 'git push --delete origin v0';
system 'git push --delete origin v0';

say 'Tagging also as v0';
say 'git tag --annotate v0 --message "Tagging v0"';
system 'git tag --annotate v0 --message "Tagging v0"';

# Pushing tags
say 'Pushing tags';
say 'git push --tags';
system 'git push --tags';

# The tagging of the version number is a part of the release process, so not need
# to create this tag separately
say 'Creating release on GitHub with auto generated release notes and discussion';
system "gh release create $version --discussion-category 'General' --generate-notes";

exit 0;
