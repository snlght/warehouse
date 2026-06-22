-ifndef(WMS_WEAPON_EVENT_HRL).
-define(WMS_WEAPON_EVENT_HRL, "wms_weapon_event_hrl").

-record(wms_weapon_event, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    weapon = <<>>,
    event_type = <<>>,
    actor = <<>>,
    event_status = <<>>,
    from_storage = <<>>,
    to_storage = <<>>,
    related_service_order = <<>>,
    related_part = <<>>,
    created_at = <<>>
}).

-endif.
