package FugitiveGame::Narration;
use strict;
use warnings;

my %TECH_POOLS = (
    phones => [
        'A relay hums, distant, on the line.',
        'The handset smells of ozone and cheap plastic.',
    ],
    unix => [
        'The terminal cursor blinks like a metronome.',
        'You picture a prompt waiting in the dark.',
    ],
    media => [
        'A copy desk trims context to fit the column.',
        'The wire service churns a thinner version of the story.',
    ],
    probation => [
        'The schedule is stamped and filed, a silent constraint.',
        'Forms move slower than people, but they do move.',
    ],
    tracking => [
        'Switch logs stack like silent witnesses.',
        'A traceroute of habits emerges in the margins.',
    ],
);

sub current_tone {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    my $stress = $meters->{stress} || 0;
    my $isolation = $meters->{isolation} || 0;
    my $paranoia = $meters->{paranoia} || 0;
    my $weight = int(($stress + $isolation + $paranoia) / 3);

    return 'calm' if $weight < 30;
    return 'wired' if $weight < 55;
    return 'paranoid' if $weight < 75;
    return 'detached';
}

sub render_text {
    my ($base_text, $tone, $context) = @_;
    $context ||= {};
    my $text = $base_text;
    if (my $tags = $context->{tone_tags}) {
        $text .= ' ' . add_tech_texture($tags) if @$tags;
    }
    return "[$tone] $text";
}

sub add_tech_texture {
    my ($tags) = @_;
    my @sentences;
    for my $tag (@{$tags || []}) {
        my $pool = $TECH_POOLS{$tag} || [];
        next unless @$pool;
        push @sentences, $pool->[0];
    }
    @sentences = @sentences[0,1] if @sentences > 2;
    return join(' ', @sentences);
}

1;
