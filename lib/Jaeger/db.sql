create table changelog (
	id serial primary key,
	title varchar(128),
	status int4 not null,
	time_begin datetime default now() not null,
	time_end datetime default now() not null,
	content text
);

create view changelog_year as select
	extract(year from sort_date) as year,
	count(*) as count,
	min(status) as status
	from changelog
	group by year;

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
	response_to_id	int4,
	status		int4 not null,
	title		text not null,
	date		timestamp with time zone default now() not null,
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

create table user_box (
	id		serial primary key,
	user_id		int4 references jaeger_user,
	title		text not null,
	url		text not null,
	last_update	timestamp with time zone
);

create table timezone (
	id		serial primary key,
	name		text not null unique,
	ofst		float not null
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
	floor((date + ofst * 3600) / 86400) * 86400 as unixdate,
	date 'epoch' + (date + ofst * 3600) * interval '1 second' as date,
	photo.status
	from photo, timezone
	where not photo.hidden and timezone_id = timezone.id and photo.date > 0;
grant select on photo_date to "www-data";

create view photo_date_view as select
	date(date_trunc('day', date)) as date,
	min(status) as status,
	count(*)
	from photo_date
	group by date(date_trunc('day', date));
grant select on photo_date_view to "www-data";

create view photo_year as select
	date_part('year', date) as year,
	min(status) as status,
	count(*)
	from photo_date
	group by year;
grant select on photo_year to "www-data";

create view photo_round as select
	round,
	min(status) as status
	from photo
	where not hidden
	group by round;
grant select on photo_round to "www-data";

create table slideshow (
	id		serial primary key,
	title		text not null,
	description	text
);

create table slideshow_photo_map (
	id		serial primary key,
	slideshow_id	int4 references slideshow,
	slideshow_index	int4 not null,
	unique(slideshow_id, slideshow_index),
	photo_id	int4 references photo,
	description	text
);

create table event (
	id		serial primary key,
	user_id		int4 references jaeger_user,

	name		text not null,
	date		text not null,
	recurring	boolean not null
);

create view recurring_event as select
	id, user_id, name, date(date(date) + interval '1 year' * ceil((current_date - date(date)) / 365.2425)) as "date" from event where recurring is true;

create table kohan_schedule (
	id		serial primary key,
	user_id		int4 references jaeger_user,
	
	day		date not null,
	unique(user_id, day),
	available	boolean not null,

	available_begin	timestamp,
	available_end	timestamp
);

create table gps_track (
	date		int4 not null unique,
	latitude	float not null,
	longitude	float not null,
	downloaded	timestamp not null default now()
);

create table vehicle (
	id		serial primary key,
	name		text not null,
	description	text
);

create table mileage (
	vehicle_id	int4 references vehicle,
	date		date not null,
	station		text not null,
	city		text not null,
	state		text not null,
	mileage		int4 not null,
	ppg		float not null,
	gal		float not null,
	total		float not null,
	valid		boolean not null default(true)
);

create table photo_set (
	id		serial primary key,
	name		text not null
);

create table photo_set_map (
	photo_set_id	int4 references photo_set,
	photo_id	int4 references photo,
	unique(photo_set_id, photo_id)
);

create index photo_set_map_set_index on photo_set_map (photo_set_id);
create index photo_set_map_photo_index on photo_set_map (photo_id);

create table tag (
	id		serial primary key,
	name		text not null
);

create table changelog_tag_map (
	tag_id		int4 references tag,
	changelog_id	int4 references changelog,
	unique(tag_id, changelog_id)
);

create index changelog_tag_map_tag_index on changelog_tag_map (tag_id);
create index changelog_tag_map_changelog_index on changelog_tag_map (changelog_id);

create view changelog_tag_view as select
	tag.name as tag,
	min(status) as status,
	count(*) as count
	from tag
	join changelog_tag_map on tag.id = changelog_tag_map.tag_id
	join changelog on changelog.id = changelog_tag_map.changelog_id
	group by tag.name;

create table photo_xref_map (
	photo_id	int4 references photo,
	changelog_id	int4 references changelog,
	unique(photo_id, changelog_id)
);

create table redirect (
	id		serial primary key,
	uri		text not null unique,
	redirect	text not null
);
