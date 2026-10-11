-ifndef(WMS_PART_REQUIREMENT_REF_HRL).
-define(WMS_PART_REQUIREMENT_REF_HRL, "wms_part_requirement_ref_hrl").

-record(wms_part_requirement_ref, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    service_order = <<>>,
    requirement = <<>>
}).

-endif.