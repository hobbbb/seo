package seo;
use Dancer ':syntax';
use Data::Dumper;
use Spreadsheet::Read;
use Lingua::Stem::Snowball;
# use Encode qw/decode/;

our $VERSION = '0.1';

get '/seo' => sub {
    template 'index';
};

post '/seo' => sub {
    my $file = request->upload('file');

    my $res;
    my $book = ReadData($file->{tempname})->[1];
    my $stemmer = Lingua::Stem::Snowball->new(lang => 'ru', encoding => 'UTF-8');

    my (%hash, %tmp);
    for my $row ($book->{minrow} .. $book->{maxrow}) {
        my $text = $book->{"A$row"};
        my $freq = $book->{"B$row"} || 0;

        my @words = split /\s+/, $text;
        $stemmer->stem_in_place(\@words);
        for my $w (@words) {
            push @{$tmp{$w}{row}}, $row;
            $tmp{$w}{cnt}++;
        }

        $hash{$row} = {
            text => $text,
            freq => $freq,
            stem => \@words,
        };
    }

    for my $w (sort { $tmp{$b}{cnt} <=> $tmp{$a}{cnt}} keys %tmp) {
        next if $tmp{$w}{cnt} <= 1;
        # print "$w - " . Dumper $tmp{$w};
        my @arr;
        for my $row (@{$tmp{$w}{row}}) {
           push @arr, { $hash{$row}{text} => $hash{$row}{freq} };
        }
        push @$res, {
            name => "Группа",
            word => \@arr,
        };
    }

    return template 'index' => {
        group => $res,
    };
};

post '/seo_old' => sub {
    my $file = request->upload('file');

    my $res;
    my $book = ReadData($file->{tempname})->[1];
=c
    my %hash;
    for my $row ($book->{minrow} .. $book->{maxrow}) {
        # my $text = decode('utf8', $book->{"A$row"});
        my $text = $book->{"A$row"};
        $hash{$row} = {
            text    => $text,
            matches => {},
            cnt     => 0,
        };
    }

    my %h = %hash;

    my ($i, %group) = (1, ());
    for my $n (keys %h) {
        next unless exists $h{$n};

        push @{$group{$i}{matches}}, $n;
        $group{$i}{cnt}++;
        my $cur = delete $h{$n};

        my @word = split /\s+/, $cur->{text};
        # print '--' . join(',', @word) . "\n" if $i == 27;
        for my $nn (keys %h) {
            my @tmp = split /\s+/, $h{$nn}{text};
            my $cnt = 0;
            for my $w (@word) {
                $cnt++ if grep(/^$w$/, @tmp);
            }

            if ($cnt >= 2) {
                # print join(',', @tmp) . "\n" if $i == 27;
                push @{$group{$i}{matches}}, $nn;
                $group{$i}{cnt}++;
                delete $h{$nn};
            }
        }

        $i++;
    }

    $i = 1;
    for my $k (sort { $group{$b}{cnt} <=> $group{$a}{cnt}} keys %group) {
        my @arr;
        for my $n (@{$group{$k}{matches}}) {
            push @arr, $hash{$n}{text};
        }
        push @$res, {
            name => "Группа $i",
            word => \@arr,
        };
        $i++;
    }
=cut

=c
    sub step1 {
        my $n = shift;

        my %h = %hash;
        my $cur = delete $h{$n};
        my @word = split /\s+/, $cur->{text};

        my $match;
        for my $nn (keys %h) {
            my @tmp = split /\s+/, $h{$nn}{text};
            for my $w (@word) {
                $match->{$nn}++ if grep(/^$w$/, @tmp);
            }
            if ($match->{$nn}) {
                if ($match->{$nn} == 1) {
                    delete $match->{$nn};
                    next;
                }

                if ($match->{$nn} > $hash{$n}{cnt}) {
                    $hash{$n}{cnt}     = $match->{$nn};
                    $hash{$n}{matches} = { $nn => 1 };
                }
                elsif ($match->{$nn} == $hash{$n}{cnt}) {
                    $hash{$n}{matches}{$nn} = 1;
                }
            }
        }
        return unless %$match;

        # my $best;
        # for $n (sort { $match->{$b} <=> $match->{$a} } keys %$match) {
        #     $best ||= $match->{$n};
        #     delete $match->{$n} if $match->{$n} != $best;
        # }

        # return $match;
    }
=cut

    return template 'index' => {
        group => $res,
    };
};

true;
