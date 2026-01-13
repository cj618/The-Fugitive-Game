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
    my ($state, $location, $chapter_title) = @_;
    my $meters = $state->{player}{meters};
    my $act = $state->{story}{act} || $state->{player}{act} || 1;
    print "\nDay $state->{player}{day} (Act $act) - ", ucfirst($state->{player}{slot}), " - Location: $location->{name}\n";
    print "Chapter: $chapter_title\n" if $chapter_title;
    print "UndergroundRep: $meters->{reputation_underground}  MediaRep: $meters->{reputation_media}  LawPressure: $meters->{law_pressure}\n";
    print "Stress: $meters->{stress}  Isolation: $meters->{isolation}  Resources: $meters->{resources}  Paranoia: $meters->{paranoia}\n";
}

sub press_wire {
    my ($headlines) = @_;
    return unless $headlines && @$headlines;
    print "\n-- Press wire --\n";
    for my $headline (@$headlines) {
        print " * $headline->{text}\n";
    }
}

sub status {
    my ($state) = @_;
    print "\n=== STATUS ===\n";
    print "Codename: $state->{player}{name}\n";
    print "Day $state->{player}{day}, Act $state->{story}{act}, Slot $state->{player}{slot}\n";
    print "Location: $state->{player}{location_id}\n";
    my $meters = $state->{player}{meters};
    print "Meters: stress $meters->{stress}, isolation $meters->{isolation}, paranoia $meters->{paranoia}, compliance $meters->{compliance}\n";
    print "Logistics: sleep_debt $meters->{sleep_debt}, equipment $meters->{equipment_integrity}, safehouse $meters->{safehouse_stability}\n";
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
    print "Endgame: stage $state->{endgame}{stage} progress $state->{endgame}{stage_progress}\n";
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
