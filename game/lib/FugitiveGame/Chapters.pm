package FugitiveGame::Chapters;
use strict;
use warnings;

sub determine_chapter_id {
    my ($state, $chapters) = @_;
    my $act = $state->{story}{act} || $state->{player}{act} || 1;
    my @act_chapters = grep { $_->{act} == $act } @{$chapters || []};
    return $state->{story}{chapter_id} if $state->{story}{chapter_id} && @act_chapters;
    return undef unless @act_chapters;
    my $index = $state->{story}{chapter_day_index} || 0;
    $index = 0 if $index < 0;
    $index = $#act_chapters if $index > $#act_chapters;
    return $act_chapters[$index]{chapter_id};
}

sub update_chapter {
    my ($state, $chapters) = @_;
    my $chapter_id = determine_chapter_id($state, $chapters);
    $state->{story}{chapter_id} = $chapter_id if $chapter_id;
    return $chapter_id;
}

sub get_chapter_title {
    my ($chapters, $chapter_id) = @_;
    for my $chapter (@{$chapters || []}) {
        return $chapter->{title} if $chapter->{chapter_id} eq $chapter_id;
    }
    return '';
}

sub get_chapter_intro_text {
    my ($chapters, $chapter_id) = @_;
    for my $chapter (@{$chapters || []}) {
        return $chapter->{narration_intro} if $chapter->{chapter_id} eq $chapter_id;
    }
    return '';
}

sub validate_chapter_refs {
    my ($chapters, $events_by_act) = @_;
    my %known = map { $_->{chapter_id} => 1 } @{$chapters || []};
    for my $act (keys %{$events_by_act || {}}) {
        for my $event (@{$events_by_act->{$act} || []}) {
            my $ref = $event->{chapter_ref};
            die "Unknown chapter_ref '$ref' in event $event->{id}\n" if $ref && !$known{$ref};
        }
    }
}

1;
