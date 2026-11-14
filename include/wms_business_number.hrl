-ifndef(WMS_BUSINESS_NUMBER_HRL).
-define(WMS_BUSINESS_NUMBER_HRL, "wms_business_number_hrl").

-record(wms_business_number, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    type = <<>>,
    number = 0,
    business_number = <<>>,
    command_id = <<>>,
    status = <<>>,
    target_id = <<>>,
    issued_at = 0,
    void_reason = <<>>,
    voided_by = <<>>,
    voided_at = 0
}).

-endif.