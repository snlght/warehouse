-ifndef(WMS_PART_REQUIREMENT_HRL).
-define(WMS_PART_REQUIREMENT_HRL, "wms_part_requirement_hrl").

-record(wms_part_requirement, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    service_order = <<>>,
    weapon = <<>>,
    diagnosis_result = <<>>,
    part_type = <<>>,
    status = <<>>,
    requested_by = <<>>,
    requested_at = 0,
    fulfilled_by_part = <<>>,
    notes = <<>>
}).

-endif.