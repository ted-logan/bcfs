create table changelog (
	id serial primary key,
	title varchar(128),
	time_begin datetime default now() not null,
	time_end datetime default now() not null,
	content text
);

create table journal (
	id serial primary key,
	entrydate date not null,
	time_begin datetime not null,
	time_end datetime not null,
	content text
);

create table lookfeel (
	label varchar(32) not null primary key,
	timestamp datetime default now() not null,
	value text
);

create table content (
	label varchar(32) not null primary key,
	parent varchar(32),
	timestamp datetime default now() not null,
	value text
);
