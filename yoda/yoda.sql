--
-- $Id: yoda.sql,v 1.2 2003-01-20 20:09:11 jaeger Exp $
--

create table yoda (
	date date not null,
	station text not null,
	city text not null,
	state text not null,
	mileage int4 not null,
	ppg float not null,
	gal float not null,
	total float not null,
	valid boolean not null default(true)
);
