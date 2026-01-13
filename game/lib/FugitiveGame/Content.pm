package FugitiveGame::Content;
use strict;
use warnings;
use JSON::PP;
use File::Spec;

sub load_json {
    my ($path) = @_;
    open my $fh, '<', $path or die "Failed to open $path: $!";
    local $/;
    my $json = <$fh>;
    close $fh;
    return JSON::PP->new->decode($json);
}

sub load_all {
    my ($base_dir) = @_;
    return {
        actions => load_json(File::Spec->catfile($base_dir, 'actions.json')),
        events => load_json(File::Spec->catfile($base_dir, 'events_act1.json')),
        locations => load_json(File::Spec->catfile($base_dir, 'locations.json')),
        npcs => load_json(File::Spec->catfile($base_dir, 'npcs.json')),
        strings => load_json(File::Spec->catfile($base_dir, 'strings.json')),
    };
}

1;
