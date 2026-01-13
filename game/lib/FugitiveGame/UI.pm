package FugitiveGame::UI;
use strict;
use warnings;

sub prompt {
    my ($text) = @_;
    print $text;
    chomp(my $input = <STDIN>);
    return $input;
}

sub menu_choice {
    my ($title, $options, $allow_commands) = @_;
    $allow_commands ||= 0;
    print "\n$title\n";
    for my $i (0 .. $#$options) {
        print "  ", $i + 1, ". ", $options->[$i], "\n";
    }
    while (1) {
        my $input = prompt('> ');
        return $input if $allow_commands && $input =~ /^(?:status|save|quit)$/i;
        if ($input =~ /^\d+$/ && $input >= 1 && $input <= @$options) {
            return $input - 1;
        }
        print "Invalid choice.\n";
    }
}

sub hud {
    my ($state, $location) = @_;
    my $meters = $state->{player}{meters};
    print "\nDay $state->{player}{day} (Act I) - ", ucfirst($state->{player}{slot}), " - Location: $location->{name}\n";
    print "UndergroundRep: $meters->{reputation_underground}  MediaRep: $meters->{reputation_media}  LawPressure: $meters->{law_pressure}\n";
    print "Stress: $meters->{stress}  Isolation: $meters->{isolation}  Resources: $meters->{resources}\n";
}

sub status {
    my ($state) = @_;
    print "\n=== STATUS ===\n";
    print "Codename: $state->{player}{name}\n";
    print "Day $state->{player}{day}, Act $state->{player}{act}, Slot $state->{player}{slot}\n";
    print "Location: $state->{player}{location_id}\n";
    print "Meters:\n";
    for my $key (sort keys %{$state->{player}{meters}}) {
        print "  $key: $state->{player}{meters}{$key}\n";
    }
    print "Skills:\n";
    for my $key (sort keys %{$state->{player}{skills}}) {
        print "  $key: $state->{player}{skills}{$key}\n";
    }
    print "Identities:\n";
    for my $identity (@{$state->{player}{identities}}) {
        print "  $identity->{alias} ($identity->{quality}) exposure $identity->{exposure}\n";
    }
    print "NPCs:\n";
    for my $npc (sort keys %{$state->{player}{npcs}}) {
        my $data = $state->{player}{npcs}{$npc};
        print "  $npc trust $data->{trust} risk $data->{risk}\n";
    }
    print "Adversary:\n";
    for my $key (sort keys %{$state->{adversary}}) {
        print "  $key: $state->{adversary}{$key}\n";
    }
    print "Media:\n";
    for my $key (sort keys %{$state->{media}}) {
        print "  $key: $state->{media}{$key}\n";
    }
    print "Flags:\n";
    for my $flag (sort keys %{$state->{player}{flags}}) {
        print "  $flag\n";
    }
    print "============\n";
}

sub confirm {
    my ($text) = @_;
    while (1) {
        my $input = prompt("$text (y/n): ");
        return 1 if $input =~ /^y/i;
        return 0 if $input =~ /^n/i;
    }
}

1;
