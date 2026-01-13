package FugitiveGame::Epilogue;
use strict;
use warnings;

sub build_packet {
    my ($state) = @_;
    my $media = $state->{media};
    my $patterns = $state->{patterns};
    my $agencies = $state->{agencies};
    my $relationships = $state->{relationships};

    my @lines;
    push @lines, "=== Epilogue ===";
    push @lines, _media_summary($media);
    push @lines, _agency_summary($agencies);
    push @lines, _pattern_summary($patterns);
    push @lines, _relationship_summary($relationships);
    push @lines, _psyche_summary($state);
    push @lines, "Outcome: arrest and processing begin.";
    return \@lines;
}

sub complete_campaign {
    my ($state) = @_;
    $state->{progress}{completed_campaign} = 1;
    $state->{progress}{unlocked_chapter_mode} = 1;
}

sub _media_summary {
    my ($media) = @_;
    return sprintf(
        "Press framing: momentum %d, accuracy %d, simplification %d.",
        $media->{momentum} || 0,
        $media->{accuracy} || 0,
        $media->{simplification} || 0,
    );
}

sub _agency_summary {
    my ($agencies) = @_;
    my $driver = 'none';
    my $max = -1;
    for my $name (keys %{$agencies || {}}) {
        my $pressure = $agencies->{$name}{pressure} || 0;
        if ($pressure > $max) {
            $max = $pressure;
            $driver = $name;
        }
    }
    return "Agency driver: $driver.";
}

sub _pattern_summary {
    my ($patterns) = @_;
    return "Pattern profile: repetition score $patterns->{repetition_score}.";
}

sub _relationship_summary {
    my ($relationships) = @_;
    my $lost = 0;
    my $total = 0;
    for my $rel (values %{$relationships || {}}) {
        $total++;
        $lost++ if ($rel->{drift} || 0) >= 70;
    }
    return "Relationships strained: $lost of $total.";
}

sub _psyche_summary {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    return sprintf(
        "Psych state: stress %d, isolation %d, paranoia %d.",
        $meters->{stress} || 0,
        $meters->{isolation} || 0,
        $meters->{paranoia} || 0,
    );
}

1;
