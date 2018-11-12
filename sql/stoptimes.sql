-- Assumes rt and gtfs schemas.

WITH d (year, month) AS (
    VALUES (2018, 5)
)
CREATE materialized view rt.stop_time_update_collection AS
SELECT
    trip_id,
    stop_id,
    (array_agg(arrival_time order by m.timestamp desc))[1] as arrival_time,
    max(m.timestamp) prediction_time
FROM rt.trip_updates t
    left join rt.stop_time_updates st ON (st.trip_update_id = t.oid)
    left join rt.messages m on mid=m.oid,
  d
WHERE extract('year' from trip_start_date) = d.year
    AND extract('month' from trip_start_date) = d.month
GROUP BY trip_id, stop_id;

-- MTA encodes the route-id in the trip-id, extract it is a shortcut to joining against gtfs.trips table
SELECT
    regexp_replace(trip_id, '^\d+_([A-Z0-9]+)(.+)$', '\1') route_id,
    stop_id,
    stop_name,
    arrival_time AT TIME ZONE 'US/Eastern',
    prediction_time AT TIME ZONE 'US/Eastern'
FROM rt.stop_time_update_collection a
    left JOIN gtfs.stops using (stop_id)
WHERE arrival_time::date > '2018-05-01'::date;
