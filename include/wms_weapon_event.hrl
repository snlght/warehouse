-ifndef(WMS_WEAPON_EVENT_HRL).
-define(WMS_WEAPON_EVENT_HRL, "wms_weapon_event_hrl").

-record(wms_weapon_event, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    weapon = <<>>,
    event_type = <<>>,
    event_status = <<>>,
    actor = <<>>,
    source_type = <<>>,
    source_id = <<>>,
    from_storage = <<>>,
    to_storage = <<>>,
    related_service_order = <<>>,
    related_part = <<>>,
    occurred_at = 0,
    recorded_at = 0,
    description = <<>>
}).

-endif.