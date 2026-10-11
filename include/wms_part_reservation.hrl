-ifndef(WMS_PART_RESERVATION_HRL).
-define(WMS_PART_RESERVATION_HRL, "wms_part_reservation_hrl").

-record(wms_part_reservation, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    part_requirement = <<>>,
    part = <<>>,
    status = <<>>,
    reserved_by = <<>>,
    reserved_at = <<>>
}).

-endif.