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
	id serial primary key,
	label varchar(32) not null unique,
	parent varchar(32),
	timestamp timestamp with time zone default now() not null,
	value text
);

create table jaeger_user (
	id		serial primary key,
	login		text not null unique,
	status		int4 not null,
	name		text not null unique,
	password	text not null,
	email		text not null,
	last_visit	timestamp with time zone default now() not null,
	webpage		text,
	about		text
);

create table comment (
	id		serial primary key,
	changelog_id	int4 references changelog,
	user_id		int4 references jaeger_user,
	response_id	int4,
	title		text not null,
	body		text not null
);

create table user_changelog_view (
	id		serial primary key,
	changelog_id	int4 references changelog,
	user_id		int4 references jaeger_user,
	date		timestamp with time zone default now() not null
);

create table user_comment_view (
	id		serial primary key,
	comment_id	int4 references comment,
	user_id		int4 references jaeger_user,
	date		timestamp with time zone default now() not null
);

create table timezone (
	id		serial primary key,
	name		text not null unique,
	ofst		int4 not null
);

create table location (
	id		serial primary key,
	state		text,
	city		text,
	name		text not null,
	unique(state, city, name)
);

create table photo (
	id		serial primary key,
	round		text not null,
	number		text not null,
	unique(round, number),
	date		int4 not null,
	timezone_id	int4 references timezone,
	location_id	int4 references location,
	hidden		boolean not null default false,
	description	text
);

create view photo_date as select
	photo.id,
	((date + ofst * 3600) / 86400) * 86400 as "date"
	from photo, timezone
	where not photo.hidden and timezone_id = timezone.id and photo.date > 0;

create table kohan_schedule (
	id		serial primary key,
	user_id		int4 references jaeger_user,
	
	day		date not null,
	unique(user_id, day),
	available	boolean not null,

	available_begin	timestamp,
	available_end	timestamp
);
