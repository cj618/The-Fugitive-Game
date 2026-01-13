package FugitiveGame::Content;
use strict;
use warnings;
use JSON::PP;
use File::Spec;
use FugitiveGame::Chapters;

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
    my $content = {
        actions => load_json(File::Spec->catfile($base_dir, 'actions.json')),
        events_by_act => {
            1 => load_json(File::Spec->catfile($base_dir, 'events_act1.json')),
            2 => load_json(File::Spec->catfile($base_dir, 'events_act2.json')),
            3 => load_json(File::Spec->catfile($base_dir, 'events_act3.json')),
            4 => load_json(File::Spec->catfile($base_dir, 'events_act4.json')),
            5 => load_json(File::Spec->catfile($base_dir, 'events_act5.json')),
        },
        locations => load_json(File::Spec->catfile($base_dir, 'locations.json')),
        npcs => load_json(File::Spec->catfile($base_dir, 'npcs.json')),
        strings => load_json(File::Spec->catfile($base_dir, 'strings.json')),
        chapters => load_json(File::Spec->catfile($base_dir, 'chapters.json')),
        agencies => load_json(File::Spec->catfile($base_dir, 'agencies.json')),
        headlines => load_json(File::Spec->catfile($base_dir, 'headlines.json')),
        scenarios => load_json(File::Spec->catfile($base_dir, 'scenarios.json')),
        narration_tones => load_json(File::Spec->catfile($base_dir, 'narration_tones.json')),
    };

    FugitiveGame::Chapters::validate_chapter_refs($content->{chapters}, $content->{events_by_act});
    _validate_historical_npcs($content);
    _validate_event_fields($content);
    return $content;
}

sub _validate_historical_npcs {
    my ($content) = @_;
    my %historical = map { $_->{id} => $_ } grep { $_->{historical} } @{$content->{npcs} || []};
    return unless %historical;
    for my $action (@{$content->{actions} || []}) {
        my $npc_id = $action->{npc_id};
        next unless $npc_id && $historical{$npc_id};
        die "Historical NPC $npc_id cannot be directly interactable\n" if ($historical{$npc_id}{interaction_mode} || '') eq 'indirect';
    }
}

sub _validate_event_fields {
    my ($content) = @_;
    for my $act (keys %{$content->{events_by_act} || {}}) {
        for my $event (@{$content->{events_by_act}{$act} || []}) {
            die "Event $event->{id} missing chapter_ref\n" unless $event->{chapter_ref};
            die "Event $event->{id} missing historical_anchor\n" unless $event->{historical_anchor};
        }
    }
}

1;
