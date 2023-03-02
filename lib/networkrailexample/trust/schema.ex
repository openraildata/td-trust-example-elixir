defmodule NetworkRailExample.TRUST.Schema do
  @moduledoc """
  One of the major differences between datafeeds and publicdatafeeds, reliability aside,
  is that empty fields are omitted on publicdatafeeds. This module is for repopulating
  empty fields with nils.

  """

  @default_header [
                    "msg_type",
                    "source_dev_id",
                    "user_id",
                    "original_data_source",
                    "msg_queue_timestamp",
                    "source_system_id"
                  ]
                  |> Enum.map(&{&1, nil})
                  |> Map.new()

  @default_bodies [
                    {"0001",
                     [
                       "schedule_source",
                       "train_file_address",
                       "schedule_end_date",
                       "train_id",
                       "tp_origin_timestamp",
                       "creation_timestamp",
                       "tp_origin_stanox",
                       "origin_dep_timestamp",
                       "train_service_code",
                       "toc_id",
                       "d1266_record_number",
                       "train_call_type",
                       "train_uid",
                       "train_call_mode",
                       "schedule_type",
                       "sched_origin_stanox",
                       "schedule_wtt_id",
                       "schedule_start_date"
                     ]},
                    {"0002",
                     [
                       "train_file_address",
                       "train_service_code",
                       "orig_loc_stanox",
                       "toc_id",
                       "dep_timestamp",
                       "division_code",
                       "loc_stanox",
                       "canx_timestamp",
                       "canx_reason_code",
                       "train_id",
                       "orig_loc_timestamp",
                       "canx_type"
                     ]},
                    {"0003",
                     [
                       "event_type",
                       "gbtt_timestamp",
                       "original_loc_stanox",
                       "planned_timestamp",
                       "timetable_variation",
                       "original_loc_timestamp",
                       "current_train_id",
                       "delay_monitoring_point",
                       "next_report_run_time",
                       "reporting_stanox",
                       "actual_timestamp",
                       "correction_ind",
                       "event_source",
                       "train_file_address",
                       "platform",
                       "division_code",
                       "train_terminated",
                       "train_id",
                       "offroute_ind",
                       "variation_status",
                       "train_service_code",
                       "toc_id",
                       "loc_stanox",
                       "auto_expected",
                       "direction_ind",
                       "route",
                       "planned_event_type",
                       "next_report_stanox",
                       "line_ind"
                     ]},
                    {"0005",
                     [
                       "current_train_id",
                       "original_loc_timestamp",
                       "train_file_address",
                       "train_service_code",
                       "toc_id",
                       "dep_timestamp",
                       "division_code",
                       "loc_stanox",
                       "train_id",
                       "original_loc_stanox",
                       "reinstatement_timestamp"
                     ]},
                    {"0006",
                     [
                       "reason_code",
                       "current_train_id",
                       "original_loc_timestamp",
                       "train_file_address",
                       "train_service_code",
                       "toc_id",
                       "dep_timestamp",
                       "coo_timestamp",
                       "division_code",
                       "loc_stanox",
                       "train_id",
                       "original_loc_stanox"
                     ]},
                    {"0007",
                     [
                       "current_train_id",
                       "train_file_address",
                       "train_service_code",
                       "revised_train_id",
                       "train_id",
                       "event_timestamp"
                     ]},
                    {"0008",
                     [
                       "original_loc_timestamp",
                       "current_train_id",
                       "train_file_address",
                       "train_service_code",
                       "dep_timestamp",
                       "loc_stanox",
                       "train_id",
                       "original_loc_stanox",
                       "event_timestamp"
                     ]}
                  ]
                  |> Enum.map(fn {message_type, keys} ->
                    {message_type, Enum.map(keys, &{&1, nil}) |> Map.new()}
                  end)
                  |> Map.new()

  def inflate_parsed_trust(%{
        "body" => body_raw,
        "header" => header_raw = %{"msg_type" => message_type}
      }) do
    header = Map.merge(@default_header, header_raw)
    body = Map.merge(Map.fetch!(@default_bodies, message_type), body_raw)

    %{"body" => body, "header" => header}
  end
end
