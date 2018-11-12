CREATE SCHEMA IF NOT EXISTS rt;
CREATE TYPE alertcause AS ENUM (
    'UNKNOWN_CAUSE',
    'TECHNICAL_PROBLEM',
    'ACCIDENT',
    'HOLIDAY',
    'WEATHER',
    'MAINTENANCE',
    'CONSTRUCTION',
    'POLICE_ACTIVITY',
    'MEDICAL_EMERGENCY'
);
CREATE TYPE alerteffect AS ENUM (
    'NO_SERVICE',
    'REDUCED_SERVICE',
    'SIGNIFICANT_DELAYS',
    'DETOUR',
    'ADDITIONAL_SERVICE',
    'MODIFIED_SERVICE',
    'OTHER_EFFECT',
    'UNKNOWN_EFFECT',
    'STOP_MOVED'
);
CREATE TYPE congestionlevel AS ENUM (
    'UNKNOWN_CONGESTION_LEVEL',
    'RUNNING_SMOOTHLY',
    'STOP_AND_GO',
    'CONGESTION'
);
CREATE TYPE occupancystatus AS ENUM (
    'EMPTY',
    'MANY_SEATS_AVAILABLE',
    'FEW_SEATS_AVAILABLE',
    'STANDING_ROOM_ONLY',
    'CRUSHED_STANDING_ROOM_ONLY',
    'FULL',
    'NOT_ACCEPTING_PASSENGERS'
);
CREATE TYPE stopstatus AS ENUM (
    'INCOMING_AT',
    'STOPPED_AT',
    'IN_TRANSIT_TO'
);
CREATE TYPE stoptimeschedule AS ENUM (
    'SCHEDULED',
    'SKIPPED',
    'NO_DATA'
);
CREATE TYPE tripschedule AS ENUM (
    'SCHEDULED',
    'ADDED',
    'UNSCHEDULED',
    'CANCELED'
);
CREATE TABLE rt.messages (
    oid serial PRIMARY KEY,
    timestamp timestamp with time zone
);
CREATE TABLE rt.replacement_periods (
    oid serial PRIMARY KEY,
    mid integer REFERENCES rt.messages(oid),
    route_id text,
    "end" timestamp with time zone
);
CREATE TABLE rt.alerts (
    oid serial PRIMARY KEY,
    mid integer REFERENCES rt.messages(oid),
    start timestamp with time zone,
    "end" timestamp with time zone,
    cause alertcause,
    effect alerteffect,
    url text,
    header_text text,
    description_text text
);
CREATE TABLE rt.entity_selectors (
    oid serial PRIMARY KEY,
    agency_id text,
    route_id text,
    route_type integer,
    stop_id text,
    trip_id text,
    trip_route_id text,
    trip_start_time interval,
    trip_start_date date,
    alert_id integer REFERENCES rt.alerts(oid)
);
CREATE TABLE rt.trip_updates (
    oid serial PRIMARY KEY,
    mid integer REFERENCES rt.messages(oid),
    trip_id text,
    route_id text,
    trip_start_time interval,
    trip_start_date date,
    schedule_relationship tripschedule,
    vehicle_id text,
    vehicle_label text,
    vehicle_license_plate text,
    "timestamp" timestamp with time zone
);
CREATE TABLE rt.stop_time_updates (
    oid serial PRIMARY KEY,
    stop_sequence integer,
    stop_id text,
    arrival_delay integer,
    arrival_time timestamp with time zone,
    arrival_uncertainty integer,
    departure_delay integer,
    departure_time timestamp with time zone,
    departure_uncertainty integer,
    schedule_relationship stoptimeschedule,
    trip_update_id integer REFERENCES rt.trip_updates(oid)
);
CREATE TABLE rt.vehicle_positions (
    mid integer REFERENCES rt.messages(oid),
    "timestamp" timestamp with time zone NOT NULL,
    trip_id text,
    route_id text,
    trip_start_time interval,
    trip_start_date date,
    vehicle_id text NOT NULL,
    vehicle_label text,
    vehicle_license_plate text,
    latitude numeric(9,6),
    longitude numeric(9,6),
    bearing numeric(5,2),
    speed numeric(4,2),
    stop_id text,
    stop_sequence text,
    stop_status stopstatus,
    occupancy_status occupancystatus,
    congestion_level congestionlevel,
    progress int,
    block_assigned text,
    dist_along_route numeric,
    dist_from_stop numeric,
    CONSTRAINT rt_vehicle_positions_pkey PRIMARY KEY ("timestamp", "trip_id", "vehicle_id")
);
CREATE TABLE rt.failures (
    filename text,
    error text
);