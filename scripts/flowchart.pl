#!/usr/bin/env perl

use 5.40.0;
use strict;
use warnings;

use Imager;
use Imager::Color;
use Imager::Fill;
use Imager::Font;

# -----------------------------------------------

sub border
{
	my($options) = @_;

	$$options{image} -> polyline(color => $$options{red}, points =>
	[
		[$$options{border_width}, $$options{border_width}],
		[$$options{image_width} - $$options{border_width}, $$options{border_width}],
		[$$options{image_width} - $$options{border_width}, $$options{image_height} - $$options{border_width}],
		[$$options{border_width}, $$options{image_height} - $$options{border_width}],
		[$$options{border_width}, $$options{border_width}]
	]) || die $$options{image} -> errstr;

} # End of border.

# -----------------------------------------------

sub box
{
	my($options, $color, $xmin, $ymin, $width, $height) = @_;

	$$options{image} -> box(color => $$options{$color}, filled => 0, box => [$xmin, $ymin, $xmin + $width, $ymin + $height]) || die $$options{image} -> errstr;

} # End of box.

# -----------------------------------------------

sub init
{
	my($options, $border, $xmin, $ymin, $width, $height) = @_;
	$$options{border_width}	= 5;
	$$options{image_width}	= 400 + 2 * $$options{border_width};
	$$options{image_height}	= 900 + 2 * $$options{border_width};
	$$options{image}		= Imager -> new(xsize => $$options{image_width}, ysize => $$options{image_height});
	$$options{black}		= Imager::Color -> new(0, 0, 0, 0) || die $$options{image} -> errstr;
	$$options{white}		= Imager::Color -> new(255, 255, 255, 0) || die $$options{image} -> errstr;
	$$options{red}			= Imager::Color -> new(255, 0, 0, 0) || die $$options{image} -> errstr;
	$$options{green}		= Imager::Color -> new(0, 255, 0, 0) || die $$options{image} -> errstr;
	$$options{font}			= Imager::Font -> new(file => "/home/ron/Documents/Fonts/AndadaPro-MediumItalic.ttf") || die $$options{image} -> errstr;
	$$options{font_size}	= 32;

} # End of init.

# -----------------------------------------------

sub message
{
	my($options, $color, $string, $x, $y) = @_;

	$$options{image} -> string
	(
		align	=> 1,
		color	=> $$options{$color},
		font	=> $$options{font},
		size	=> $$options{font_size},
		string	=> $string,
		x		=> $x,
		y		=> $y,
	) || die $$options{image} -> errstr;

} # End of message.

# -----------------------------------------------

my(%options);

init(\%options);

$options{image} -> box(filled => 1, color => $options{black});

border(\%options);
box(\%options, 'red', 20, 20, 150, 60);
box(\%options, 'red', 20, 160, 150, 60);

message(\%options, 'white', 'Hello', 25, 30);
message(\%options, 'green', 'Goodbye', 25, 140);

$options{image} -> string(
	color => $options{white},
	font => $options{font},
	size => $options{font_size},
	string => 'Hello World!',
	x => 250,
	y => 250,
) || die $options{image} -> errstr;

my($file_name) = 'data/one.png';

$options{image} -> write(file => $file_name) || die $options{image} -> errstr;
