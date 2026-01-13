package FugitiveGame::State;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp);

sub new_game {
    my ($class, %args) = @_;
    my $name = $args{name} // 'Player';
    my $rng_mode = $args{rng_mode} // 'seeded';
    my $seed = $args{seed} // 12345;

    my $state = {
        player => {
            name => $name,
            day => 1,
            act => 1,
            slot => 'morning',
            location_id => 'apartment',
            meters => {
                reputation_underground => 20,
                reputation_media => 5,
                law_pressure => 10,
                stress => 20,
                isolation => 15,
                resources => 60,
            },
            skills => {
                social_engineering => 4,
                telephony => 3,
                unix_systems => 3,
                tradecraft => 3,
            },
            identities => [
                { alias => 'Primary Alias', quality => 'medium', exposure => 0 },
            ],
            npcs => {},
            flags => {},
            rng => {
                mode => $rng_mode,
                seed => $seed,
            },
        },
        adversary => {
            awareness => 10,
            pattern_knowledge => 5,
            resource_commitment => 5,
            technical_focus => 5,
        },
        media => {
            demonization => 5,
            accuracy => 30,
            momentum => 5,
        },
        daily => {
            exposure => 0,
            high_risk => 0,
            travel => 0,
            payphone => 0,
        },
        log_file => undef,
    };

    return $state;
}

sub ensure_npcs {
    my ($state, $npcs) = @_;
    for my $npc (@{$npcs || []}) {
        my $id = $npc->{id};
        next unless $id;
        $state->{player}{npcs}{$id} //= {
            trust => $npc->{base_trust} // 20,
            risk => $npc->{base_risk} // 10,
            last_contact_day => 0,
        };
    }
}

sub clamp_state {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    for my $key (keys %{$meters}) {
        $meters->{$key} = clamp($meters->{$key}, 0, 100);
    }
    my $skills = $state->{player}{skills};
    for my $key (keys %{$skills}) {
        $skills->{$key} = clamp($skills->{$key}, 1, 10);
    }
    for my $identity (@{$state->{player}{identities}}) {
        $identity->{exposure} = clamp($identity->{exposure}, 0, 100);
    }
    for my $section (qw(adversary media)) {
        for my $key (keys %{$state->{$section}}) {
            $state->{$section}{$key} = clamp($state->{$section}{$key}, 0, 100);
        }
    }
}

1;
