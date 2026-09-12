-ifndef(WMS_DIAGNOSIS_RESULT_HRL).
-define(WMS_DIAGNOSIS_RESULT_HRL, "wms_diagnosis_result_hrl").

-record(wms_diagnosis_result, {
    id = kvs:seq([],[]),
    next = [],
    prev = [],
    cn = <<>>,
    
    service_order = <<>>,
    weapon = <<>>,
    outcome = <<>>,
    faults = [],
    diagnosed_by = <<>>,
    diagnosed_at = 0,
    notes = <<>>
}).

-endif.