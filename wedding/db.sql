create table gifts (
	id		serial primary key,
	name		text,
	address		text,
	gift		text,
	arrived		date,
	note_sent	date,
	side		int4
);
