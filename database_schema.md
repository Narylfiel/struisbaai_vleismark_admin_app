# Database schema (public)

**Source:** Live Supabase — `information_schema.columns` (full column list) and `foreign_key_constraints` from Supabase schema metadata export.
**Generated:** 2026-03-24

## Tables and columns

### account_awol_records

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| account_id | uuid | NO |
| awol_date | date | NO |
| reason | text | YES |
| recorded_by | uuid | NO |
| created_at | timestamp with time zone | YES |

### account_transactions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| account_id | uuid | NO |
| transaction_type | text | NO |
| reference | text | YES |
| description | text | YES |
| amount | numeric | NO |
| running_balance | numeric | YES |
| payment_method | text | YES |
| proof_url | text | YES |
| recorded_by | uuid | YES |
| transaction_date | date | NO |
| created_at | timestamp with time zone | YES |

### admin_notifications

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| title | text | NO |
| body | text | YES |
| type | text | NO |
| metadata | jsonb | NO |
| created_at | timestamp with time zone | NO |

### admin_roles

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| role_name | text | NO |
| display_name | text | NO |
| description | text | YES |
| color_hex | text | YES |
| sort_order | integer | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |

### announcements

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| title | text | NO |
| content | text | NO |
| announcement_type | text | NO |
| priority | text | NO |
| is_active | boolean | YES |
| start_date | date | NO |
| end_date | date | YES |
| target_audience | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| image_url | text | YES |

### audit_log

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| action | text | NO |
| table_name | text | YES |
| record_id | text | YES |
| staff_id | uuid | YES |
| staff_name | text | YES |
| authorised_by | uuid | YES |
| authorised_name | text | YES |
| old_value | jsonb | YES |
| new_value | jsonb | YES |
| details | text | YES |
| severity | text | YES |
| ip_address | text | YES |
| created_at | timestamp with time zone | YES |
| module | text | YES |
| description | text | YES |
| entity_type | text | YES |
| entity_id | text | YES |

### bank_reconciliation_matches

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| bank_transaction_id | uuid | NO |
| match_type | text | NO |
| matched_record_id | uuid | YES |
| matched_amount | numeric | YES |
| account_code | text | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |

### bank_transactions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| post_date | date | NO |
| trans_date | date | NO |
| description | text | NO |
| reference | text | YES |
| fees | numeric | NO |
| amount | numeric | NO |
| balance | numeric | YES |
| status | text | NO |
| account_code | text | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### business_accounts

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| account_type | text | YES |
| email | text | YES |
| phone | text | YES |
| balance | numeric | YES |
| credit_limit | numeric | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| contact_person | text | YES |
| whatsapp | text | YES |
| vat_number | text | YES |
| credit_terms_days | integer | YES |
| auto_suspend | boolean | YES |
| auto_suspend_days | integer | YES |
| suspended | boolean | YES |
| suspended_at | timestamp with time zone | YES |
| notes | text | YES |
| address | text | YES |
| active | boolean | YES |
| suspension_recommended | boolean | YES |

### business_settings

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| business_name | text | YES |
| trading_name | text | YES |
| address | text | YES |
| vat_number | text | YES |
| phone | text | YES |
| email | text | YES |
| logo_url | text | YES |
| working_hours_start | time without time zone | YES |
| working_hours_end | time without time zone | YES |
| overtime_after_daily | numeric | YES |
| overtime_after_weekly | numeric | YES |
| sunday_pay_multiplier | numeric | YES |
| public_holiday_multiplier | numeric | YES |
| blockman_verification | boolean | YES |
| shrinkage_tolerance_pct | numeric | YES |
| auto_void_parked_hours | integer | YES |
| receipt_footer | text | YES |
| scale_brand | text | YES |
| scale_weight_prefix | integer | YES |
| scale_price_prefix | integer | YES |
| scale_plu_digits | integer | YES |
| scale_primary_mode | text | YES |
| vat_standard | numeric | YES |
| vat_zero_rated | numeric | YES |
| event_spike_multiplier | numeric | YES |
| currency_symbol | text | YES |
| country | text | YES |
| timezone | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| setting_key | text | YES |
| setting_value | jsonb | YES |
| scale_output_path | text | YES |
| scale_ip_address | text | YES |
| scale_last_sync | timestamp with time zone | YES |
| closing_time | time without time zone | YES |
| clock_out_grace_minutes | integer | NO |
| overnight_alert_email | text | YES |
| points_per_rand | numeric | YES |
| tier_member_threshold | numeric | YES |
| tier_elite_threshold | numeric | YES |
| tier_vip_threshold | numeric | YES |

### carcass_breakdown_sessions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| intake_id | uuid | NO |
| carcass_number | integer | NO |
| actual_weight_kg | numeric | NO |
| template_id | uuid | YES |
| started_at | timestamp with time zone | YES |
| completed_at | timestamp with time zone | YES |
| processed_by | uuid | NO |
| status | text | NO |
| notes | text | YES |

### carcass_cuts

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| carcass_id | uuid | NO |
| cut_name | text | NO |
| weight | numeric | YES |
| inventory_item_id | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| intake_id | uuid | YES |
| expected_kg | numeric | YES |
| actual_kg | numeric | YES |
| plu_code | integer | YES |
| sellable | boolean | YES |
| breakdown_date | timestamp with time zone | YES |

### carcass_intakes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| intake_date | date | NO |
| species | text | NO |
| supplier_id | uuid | YES |
| hunter_job_id | uuid | YES |
| weight_in | numeric | YES |
| weight_out | numeric | YES |
| status | text | NO |
| job_type | text | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| remaining_weight | numeric | YES |
| variance_pct | numeric | YES |
| reference_number | text | YES |
| yield_template_id | uuid | YES |
| delivery_date | date | YES |
| carcass_type | text | YES |

### categories

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| color_code | text | YES |
| sort_order | integer | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |
| notes | text | YES |
| updated_at | timestamp with time zone | YES |
| is_active | boolean | YES |
| parent_id | uuid | YES |
| available_online | boolean | YES |

### chart_of_accounts

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| code | text | NO |
| name | text | NO |
| account_type | text | NO |
| parent_id | uuid | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| account_code | text | YES |
| account_name | text | YES |
| subcategory | text | YES |
| sort_order | integer | YES |

### compliance_records

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| document_type | text | NO |
| expiry_date | date | YES |
| file_url | text | YES |
| is_verified | boolean | YES |
| verified_by | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### custom_reward_campaigns

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| target_tier | text | NO |
| max_slots | integer | NO |
| min_kg | numeric | NO |
| discount_type | text | NO |
| discount_value | numeric | NO |
| collection_days_min | integer | NO |
| collection_days_max | integer | NO |
| status | text | NO |
| announcement_id | uuid | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |

### custom_reward_ingredients

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| campaign_id | uuid | NO |
| ingredient_type | text | NO |
| name | text | NO |
| price_per_kg | numeric | YES |
| sort_order | integer | YES |
| active | boolean | YES |

### custom_reward_orders

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| campaign_id | uuid | NO |
| customer_id | uuid | NO |
| boerewors_name | text | NO |
| meat_base_id | uuid | YES |
| spice_mode | text | NO |
| spice_profile_id | uuid | YES |
| spice_addon_ids | ARRAY | YES |
| customer_vision | text | YES |
| kg_ordered | numeric | NO |
| original_price | numeric | NO |
| discount_applied | numeric | NO |
| price_total | numeric | NO |
| ai_recipe | jsonb | YES |
| ai_recipe_generated_at | timestamp with time zone | YES |
| owner_recipe | jsonb | YES |
| recipe_finalised_at | timestamp with time zone | YES |
| terms_accepted_at | timestamp with time zone | YES |
| payfast_reference | text | YES |
| status | text | NO |
| paid_at | timestamp with time zone | YES |
| ready_notified_at | timestamp with time zone | YES |
| fulfilled_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | YES |

### customer_announcements

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| title | text | NO |
| body | text | NO |
| channel | text | NO |
| sent_at | timestamp with time zone | YES |
| recipient_count | integer | YES |
| status | text | NO |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| image_url | text | YES |

### customer_invoices

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| invoice_number | text | NO |
| account_id | uuid | YES |
| invoice_date | date | NO |
| due_date | date | NO |
| line_items | jsonb | YES |
| subtotal | numeric | NO |
| tax_rate | numeric | YES |
| tax_amount | numeric | NO |
| total | numeric | NO |
| status | text | NO |
| payment_date | date | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| transaction_id | uuid | YES |
| email_sent_at | timestamp with time zone | YES |
| email_sent_to | text | YES |
| email_delivery_status | text | YES |
| source | text | YES |

### customer_recipe_category_assignments

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| recipe_id | uuid | NO |
| option_id | uuid | NO |

### customer_recipe_category_options

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| type_id | uuid | NO |
| name | text | NO |
| sort_order | integer | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |

### customer_recipe_category_types

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| sort_order | integer | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### customer_recipe_images

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| recipe_id | uuid | NO |
| image_url | text | NO |
| sort_order | integer | YES |
| is_primary | boolean | YES |
| created_at | timestamp with time zone | YES |

### customer_recipe_ingredients

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| recipe_id | uuid | NO |
| ingredient_text | text | NO |
| is_optional | boolean | YES |
| sort_order | integer | YES |

### customer_recipe_steps

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| recipe_id | uuid | NO |
| step_number | integer | NO |
| instruction_text | text | NO |

### customer_recipes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| title | text | NO |
| description | text | YES |
| serving_size | integer | YES |
| prep_time_minutes | integer | YES |
| cook_time_minutes | integer | YES |
| status | text | NO |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| tag | text | NO |
| image_url | text | YES |
| ingredients | text | YES |
| instructions | text | YES |

### donations

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| donor_name | text | NO |
| donation_type | text | NO |
| donation_value | numeric | YES |
| donation_date | date | NO |
| payment_status | text | NO |
| contact_details | text | YES |
| purpose | text | YES |
| tax_certificate_issued | boolean | YES |
| notes | text | YES |
| recorded_by | uuid | NO |
| created_at | timestamp with time zone | YES |

### dryer_batch_ingredients

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| batch_id | uuid | NO |
| inventory_item_id | uuid | NO |
| quantity_used | numeric | NO |
| added_at | timestamp with time zone | YES |

### dryer_batches

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| start_date | date | YES |
| end_date | date | YES |
| items | jsonb | YES |
| weight_in | numeric | YES |
| weight_out | numeric | YES |
| shrinkage_pct | numeric | YES |
| status | text | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| input_product_id | uuid | YES |
| output_product_id | uuid | YES |
| recipe_id | uuid | YES |
| started_at | timestamp with time zone | YES |
| batch_number | text | YES |
| loaded_at | timestamp with time zone | YES |
| completed_at | timestamp with time zone | YES |
| drying_hours | numeric | YES |
| kwh_per_hour | numeric | YES |
| electricity_cost | numeric | YES |
| planned_hours | numeric | YES |
| production_batch_id | uuid | YES |

### email_log

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| invoice_id | uuid | YES |
| recipient_email | text | NO |
| subject | text | YES |
| status | text | YES |
| error_message | text | YES |
| sent_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | YES |

### equipment_register

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| asset_number | text | NO |
| description | text | NO |
| category | text | NO |
| purchase_date | date | NO |
| purchase_price | numeric | NO |
| supplier_name | text | YES |
| location | text | YES |
| depreciation_method | text | YES |
| useful_life_years | integer | NO |
| salvage_value | numeric | YES |
| accumulated_depreciation | numeric | YES |
| current_value | numeric | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_by | uuid | YES |
| service_log | jsonb | YES |
| status | text | YES |
| depreciation_rate | numeric | YES |

### event_sales_history

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| event_id | uuid | NO |
| date | date | NO |
| sales_amount | numeric | NO |
| transaction_count | integer | NO |
| avg_transaction | numeric | YES |
| top_products | jsonb | YES |
| created_at | timestamp with time zone | YES |
| kg_sold | numeric | YES |
| baseline_amount | numeric | YES |
| variance_pct | numeric | YES |
| week_start | date | YES |
| year | integer | YES |

### event_tags

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| event_name | text | NO |
| event_date | date | NO |
| notes | text | YES |
| affected_categories | ARRAY | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| event_type | text | YES |
| start_date | date | YES |
| end_date | date | YES |
| recurrence_month | integer | YES |
| recurrence_week | integer | YES |
| reminder_days_before | integer | YES |
| dismissed | boolean | YES |
| total_revenue | numeric | YES |
| total_kg_sold | numeric | YES |
| total_transactions | integer | YES |
| baseline_revenue | numeric | YES |
| revenue_variance_pct | numeric | YES |
| auto_detected | boolean | YES |
| spike_date | date | YES |

### financial_periods

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| period_name | text | NO |
| start_date | date | NO |
| end_date | date | YES |
| is_locked | boolean | NO |
| period_type | text | NO |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | NO |

### hunter_job_processes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| job_id | uuid | NO |
| process_type | text | NO |
| started_at | timestamp with time zone | YES |
| completed_at | timestamp with time zone | YES |
| processed_by | uuid | NO |
| weight_before_kg | numeric | YES |
| weight_after_kg | numeric | YES |
| notes | text | YES |

### hunter_jobs

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| job_date | date | NO |
| hunter_name | text | NO |
| contact_phone | text | YES |
| species | text | NO |
| weight_in | numeric | YES |
| processing_instructions | jsonb | YES |
| status | text | NO |
| cuts | jsonb | YES |
| charge_total | numeric | YES |
| paid | boolean | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| customer_name | text | YES |
| customer_phone | text | YES |
| animal_type | text | YES |
| estimated_weight | numeric | YES |
| total_amount | numeric | YES |
| species_list | jsonb | YES |
| services_list | jsonb | YES |
| materials_list | jsonb | YES |
| processing_options | jsonb | YES |
| animal_count | integer | YES |

### hunter_process_materials

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| process_id | uuid | NO |
| material_type | text | NO |
| item_name | text | NO |
| quantity_used | numeric | NO |
| unit | text | NO |
| cost | numeric | YES |
| used_at | timestamp with time zone | YES |

### hunter_service_config

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| species | text | NO |
| base_rate | numeric | YES |
| per_kg_rate | numeric | YES |
| cut_options | jsonb | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### hunter_services

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| description | text | YES |
| base_price | numeric | NO |
| price_per_kg | numeric | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| cut_options | jsonb | YES |
| inventory_item_id | uuid | YES |
| service_category | text | YES |

### hunter_species

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| description | text | YES |
| typical_weight_min | numeric | YES |
| typical_weight_max | numeric | YES |
| is_active | boolean | YES |
| sort_order | integer | YES |
| created_at | timestamp with time zone | YES |

### inventory_items

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| plu_code | integer | NO |
| name | text | NO |
| pos_display_name | text | YES |
| scale_label_name | text | YES |
| sku | text | YES |
| barcode | text | YES |
| barcode_prefix | text | YES |
| item_type | text | YES |
| category | text | YES |
| sub_category | text | YES |
| scale_item | boolean | YES |
| ishida_sync | boolean | YES |
| text_lookup_code | text | YES |
| sell_price | numeric | YES |
| cost_price | numeric | YES |
| average_cost_price | numeric | YES |
| target_margin_pct | numeric | YES |
| freezer_markdown_pct | numeric | YES |
| vat_group | text | YES |
| price_last_changed | timestamp with time zone | YES |
| stock_control_type | text | YES |
| unit_type | text | YES |
| allow_sell_by_fraction | boolean | YES |
| pack_size | numeric | YES |
| stock_on_hand_fresh | numeric | YES |
| stock_on_hand_frozen | numeric | YES |
| reorder_level | numeric | YES |
| slow_moving_trigger_days | integer | YES |
| shelf_life_fresh | integer | YES |
| shelf_life_frozen | integer | YES |
| carcass_link | text | YES |
| recipe_link | uuid | YES |
| is_manufactured | boolean | YES |
| dryer_product | boolean | YES |
| supplier_id | uuid | YES |
| image_url | text | YES |
| dietary_tags | ARRAY | YES |
| allergen_info | ARRAY | YES |
| internal_notes | text | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| supplier_ids | jsonb | YES |
| average_cost | numeric | YES |
| storage_location_ids | jsonb | YES |
| carcass_link_id | uuid | YES |
| dryer_biltong_product | boolean | YES |
| modifier_group_ids | jsonb | YES |
| recipe_id | uuid | YES |
| dryer_product_type | text | YES |
| manufactured_item | boolean | YES |
| last_edited_by | uuid | YES |
| last_edited_at | timestamp with time zone | YES |
| category_id | uuid | YES |
| current_stock | numeric | YES |
| product_type | text | YES |
| sub_category_id | uuid | YES |
| available_online | boolean | YES |
| available_pos | boolean | YES |
| available_loyalty_app | boolean | YES |
| online_description | text | YES |
| online_image_url | text | YES |
| online_sort_order | integer | YES |
| shrinkage_allowance_pct | numeric | YES |
| is_frozen_variant | boolean | YES |
| min_stock_alert | numeric | YES |
| scale_shelf_life | integer | YES |
| label_format | text | YES |
| bar_flag | text | YES |
| department_no | text | YES |
| best_by | integer | YES |
| des_li1 | text | YES |
| des_li2 | text | YES |
| des_li3 | text | YES |
| des_li4 | text | YES |
| font_line1 | integer | YES |
| font_line2 | integer | YES |
| font_line3 | integer | YES |
| font_line4 | integer | YES |
| has_ingredient | boolean | YES |
| ingredient_no | text | YES |
| cdv | integer | YES |
| weighed | boolean | YES |
| online_display_name | text | YES |
| online_min_stock_threshold | numeric | NO |
| delivery_eligible | boolean | NO |
| is_best_seller | boolean | YES |
| is_featured | boolean | YES |
| online_ingredients | text | YES |
| online_allergens | text | YES |
| online_cooking_tips | text | YES |
| online_weight_description | text | YES |
| parent_stock_item_id | uuid | YES |
| stock_deduction_qty | numeric | YES |
| stock_deduction_unit | text | YES |

### invoice_line_items

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| invoice_id | uuid | NO |
| description | text | NO |
| quantity | numeric | NO |
| unit_price | numeric | NO |
| line_total | numeric | YES |
| sort_order | integer | YES |
| created_at | timestamp with time zone | YES |

### invoices

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| invoice_number | text | NO |
| account_id | uuid | YES |
| invoice_date | date | NO |
| due_date | date | YES |
| line_items | jsonb | YES |
| subtotal | numeric | YES |
| tax_rate | numeric | YES |
| tax_amount | numeric | YES |
| total | numeric | YES |
| status | text | NO |
| payment_date | date | YES |
| created_by | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| supplier_id | uuid | YES |

### leave_balances

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| employee_id | uuid | NO |
| annual_leave_balance | numeric | YES |
| sick_leave_balance | numeric | YES |
| family_leave_balance | numeric | YES |
| last_updated | timestamp with time zone | YES |
| last_accrual_date | date | YES |
| staff_id | uuid | YES |

### leave_history

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| leave_type | text | NO |
| start_date | date | NO |
| end_date | date | NO |
| days_taken | numeric | NO |
| source | text | NO |
| source_request_id | uuid | YES |
| notes | text | YES |
| recorded_by | uuid | YES |
| created_at | timestamp with time zone | YES |

### leave_requests

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| leave_type | text | NO |
| start_date | date | NO |
| end_date | date | NO |
| days_requested | numeric | YES |
| status | text | NO |
| approved_by | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| employee_id | uuid | YES |
| review_notes | text | YES |
| reviewed_at | timestamp with time zone | YES |

### ledger_entries

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| account_id | uuid | YES |
| entry_date | date | NO |
| description | text | YES |
| debit | numeric | YES |
| credit | numeric | YES |
| reference | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| source | text | YES |
| metadata | jsonb | YES |
| account_code | text | YES |
| account_name | text | YES |
| reference_type | text | YES |
| reference_id | uuid | YES |
| recorded_by | uuid | YES |

### loyalty_customers

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| full_name | text | NO |
| email | text | YES |
| phone | text | YES |
| whatsapp | text | YES |
| birthday | date | YES |
| physical_address | text | YES |
| loyalty_tier | text | YES |
| points_balance | integer | YES |
| total_spend | numeric | YES |
| visit_count | integer | YES |
| favourite_products | ARRAY | YES |
| notes | text | YES |
| active | boolean | YES |
| joined_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| tags | jsonb | YES |
| membership_number | text | YES |
| auth_uid | uuid | YES |
| last_purchase_date | date | YES |
| points_expiry_date | date | YES |
| referral_code | text | YES |

### loyalty_notifications

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| customer_id | uuid | NO |
| notification_type | text | NO |
| title | text | NO |
| body | text | NO |
| scheduled_for | date | NO |
| sent_at | timestamp with time zone | YES |
| status | text | YES |
| metadata | jsonb | YES |
| created_at | timestamp with time zone | YES |

### loyalty_points_log

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| customer_id | uuid | NO |
| transaction_id | uuid | YES |
| points_delta | integer | NO |
| points_earned | integer | YES |
| amount | numeric | YES |
| action_type | text | NO |
| type | text | YES |
| notes | text | YES |
| staff_id | uuid | YES |
| created_at | timestamp with time zone | YES |

### loyalty_tier_config

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| tier_key | text | NO |
| tier_label | text | NO |
| points_required | integer | NO |
| sort_order | integer | NO |
| perks | jsonb | NO |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| color_hex | text | YES |
| icon | text | YES |
| decay_reset_points | integer | YES |

### message_logs

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| message_sid | text | YES |
| to_number | text | NO |
| message_content | text | YES |
| status | text | NO |
| error_message | text | YES |
| sent_at | timestamp with time zone | NO |

### modifier_groups

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| required | boolean | YES |
| allow_multiple | boolean | YES |
| max_selections | integer | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |
| is_required | boolean | YES |
| updated_at | timestamp with time zone | YES |
| sort_order | integer | YES |

### modifier_items

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| modifier_group_id | uuid | NO |
| name | text | NO |
| price_adjustment | numeric | YES |
| track_inventory | boolean | YES |
| linked_item_id | uuid | YES |
| sort_order | integer | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |
| inventory_item_id | uuid | YES |
| updated_at | timestamp with time zone | YES |

### online_order_items

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| order_id | uuid | NO |
| inventory_item_id | uuid | NO |
| plu_code | integer | NO |
| product_name | text | NO |
| qty | integer | NO |
| unit_price | numeric | NO |
| vat_rate | numeric | NO |
| line_total | numeric | NO |
| created_at | timestamp with time zone | NO |

### online_order_print_queue

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| order_id | uuid | NO |
| order_data | jsonb | NO |
| printed | boolean | NO |
| printed_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | NO |

### online_orders

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| order_number | text | NO |
| customer_id | uuid | NO |
| parked_sale_id | uuid | YES |
| status | text | NO |
| payment_method | text | NO |
| payment_status | text | NO |
| payfast_payment_id | text | YES |
| subtotal | numeric | NO |
| vat_amount | numeric | NO |
| total | numeric | NO |
| notes | text | YES |
| collection_date | date | YES |
| collection_slot | text | YES |
| is_delivery | boolean | NO |
| delivery_address | text | YES |
| delivery_fee | numeric | NO |
| created_at | timestamp with time zone | NO |
| updated_at | timestamp with time zone | NO |
| confirmed_at | timestamp with time zone | YES |
| ready_at | timestamp with time zone | YES |
| collected_at | timestamp with time zone | YES |
| cancelled_at | timestamp with time zone | YES |
| cancellation_reason | text | YES |
| is_test | boolean | NO |

### online_product_categories

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| inventory_item_id | uuid | NO |
| category_id | uuid | NO |
| created_at | timestamp with time zone | YES |

### online_product_recipes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| inventory_item_id | uuid | NO |
| customer_recipe_id | uuid | NO |
| display_order | integer | YES |
| created_at | timestamp with time zone | YES |

### online_product_suggestions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| source_product_id | uuid | NO |
| suggested_product_id | uuid | NO |
| suggestion_type | text | NO |
| display_order | integer | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |

### opening_balances

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| account_code | text | NO |
| account_name | text | NO |
| balance_date | date | NO |
| debit_balance | numeric | NO |
| credit_balance | numeric | NO |
| is_confirmed | boolean | NO |
| notes | text | YES |
| recorded_by | uuid | YES |
| created_at | timestamp with time zone | NO |

### parked_sales

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| reference | text | NO |
| source | text | YES |
| hunter_job_id | uuid | YES |
| customer_name | text | YES |
| customer_phone | text | YES |
| line_items | jsonb | NO |
| subtotal | numeric | YES |
| notes | text | YES |
| status | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| online_order_id | uuid | YES |
| customer_id | uuid | YES |
| payment_status | text | NO |

### payroll_entries

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| pay_period_start | date | NO |
| pay_period_end | date | NO |
| pay_frequency | text | NO |
| gross_pay | numeric | YES |
| deductions | numeric | YES |
| net_pay | numeric | YES |
| status | text | NO |
| approved_by | uuid | YES |
| paid_at | timestamp with time zone | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| period_id | uuid | YES |
| regular_hours | numeric | YES |
| overtime_hours | numeric | YES |
| sunday_hours | numeric | YES |
| public_holiday_hours | numeric | YES |
| regular_pay | numeric | YES |
| overtime_pay | numeric | YES |
| sunday_pay | numeric | YES |
| public_holiday_pay | numeric | YES |
| uif_employee | numeric | YES |
| uif_employer | numeric | YES |
| advance_deduction | numeric | YES |
| meat_purchase_deduction | numeric | YES |
| other_deductions | numeric | YES |

### payroll_periods

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| period_name | text | NO |
| start_date | date | NO |
| end_date | date | NO |
| status | text | NO |
| processed_at | timestamp with time zone | YES |
| processed_by | uuid | YES |
| total_gross | numeric | YES |
| total_deductions | numeric | YES |
| total_net | numeric | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### petty_cash_movements

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| till_session_id | uuid | NO |
| direction | text | NO |
| amount | numeric | NO |
| reason | text | NO |
| recorded_by | uuid | NO |
| recorded_at | timestamp with time zone | NO |
| terminal_id | text | YES |
| created_at | timestamp with time zone | YES |

### printer_config

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | YES |
| ip_address | text | YES |
| port | integer | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### product_suppliers

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| inventory_item_id | uuid | NO |
| supplier_id | uuid | NO |
| supplier_product_code | text | YES |
| supplier_product_name | text | YES |
| unit_price | numeric | YES |
| lead_time_days | integer | YES |
| is_preferred | boolean | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### production_batch_ingredients

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| batch_id | uuid | NO |
| ingredient_id | uuid | NO |
| planned_quantity | numeric | NO |
| actual_quantity | numeric | YES |
| used_at | timestamp with time zone | YES |

### production_batch_outputs

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| batch_id | uuid | NO |
| inventory_item_id | uuid | NO |
| qty_produced | numeric | NO |
| unit | text | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |

### production_batches

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| batch_date | date | NO |
| recipe_id | uuid | YES |
| qty_produced | numeric | YES |
| unit | text | YES |
| cost_total | numeric | YES |
| notes | text | YES |
| status | text | NO |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| output_product_id | uuid | YES |
| parent_batch_id | uuid | YES |
| split_note | text | YES |
| is_split_parent | boolean | YES |

### profiles

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| full_name | text | NO |
| role | text | NO |
| pin_hash | text | NO |
| phone | text | YES |
| email | text | YES |
| id_number | text | YES |
| start_date | date | YES |
| employment_type | text | YES |
| hourly_rate | numeric | YES |
| monthly_salary | numeric | YES |
| payroll_frequency | text | YES |
| max_discount_pct | numeric | YES |
| bank_name | text | YES |
| bank_account | text | YES |
| bank_branch_code | text | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| is_active | boolean | YES |
| permissions | jsonb | YES |

### promotion_products

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| promotion_id | uuid | YES |
| inventory_item_id | uuid | YES |
| role | text | NO |
| quantity | numeric | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### promotion_suggestions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| suggestion_type | text | NO |
| product_id | uuid | YES |
| title | text | NO |
| description | text | NO |
| suggested_action | text | NO |
| points_multiplier | numeric | YES |
| estimated_margin | numeric | YES |
| status | text | YES |
| created_at | timestamp with time zone | YES |
| reviewed_at | timestamp with time zone | YES |
| reviewed_by | uuid | YES |

### promotions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| description | text | YES |
| status | text | NO |
| promotion_type | text | NO |
| trigger_config | jsonb | NO |
| reward_config | jsonb | NO |
| audience | ARRAY | NO |
| channels | ARRAY | NO |
| start_date | date | YES |
| end_date | date | YES |
| start_time | time without time zone | YES |
| end_time | time without time zone | YES |
| days_of_week | ARRAY | YES |
| usage_limit | integer | YES |
| usage_count | integer | YES |
| requires_manual_activation | boolean | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| terms_and_conditions | text | YES |

### public_holidays

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| holiday_date | date | NO |
| holiday_name | text | NO |
| is_active | boolean | NO |
| created_at | timestamp with time zone | YES |

### purchase_order_lines

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| purchase_order_id | uuid | NO |
| inventory_item_id | uuid | NO |
| quantity | numeric | NO |
| unit | text | YES |
| unit_price | numeric | YES |
| line_total | numeric | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |

### purchase_orders

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| po_number | text | NO |
| supplier_id | uuid | NO |
| status | text | NO |
| order_date | date | NO |
| expected_date | date | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### purchase_sale_agreement

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| agreement_number | text | NO |
| agreement_type | text | NO |
| party_name | text | NO |
| party_contact | text | YES |
| asset_description | text | NO |
| agreed_price | numeric | NO |
| agreement_date | date | NO |
| completion_date | date | YES |
| status | text | NO |
| payment_terms | text | YES |
| special_conditions | text | YES |
| created_by | uuid | NO |
| created_at | timestamp with time zone | YES |
| account_id | uuid | YES |

### purchase_sale_payments

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| agreement_id | uuid | NO |
| payment_date | date | NO |
| amount | numeric | NO |
| payment_method | text | NO |
| reference_number | text | YES |
| notes | text | YES |
| recorded_by | uuid | NO |
| created_at | timestamp with time zone | YES |

### recipe_ingredients

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| recipe_id | uuid | NO |
| inventory_item_id | uuid | YES |
| ingredient_name | text | NO |
| quantity | numeric | NO |
| unit | text | NO |
| sort_order | integer | YES |
| is_optional | boolean | YES |
| notes | text | YES |

### recipes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| category | text | YES |
| ingredients | jsonb | YES |
| instructions | text | YES |
| yield_qty | numeric | YES |
| yield_unit | text | YES |
| cost_per_unit | numeric | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| output_product_id | uuid | YES |
| expected_yield_pct | numeric | YES |
| batch_size_kg | numeric | YES |
| cook_time_minutes | bigint | YES |
| created_by | uuid | YES |
| prep_time_minutes | integer | YES |
| required_role | text | YES |
| goes_to_dryer | boolean | YES |
| dryer_output_product_id | uuid | YES |

### referrals

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| referrer_id | uuid | NO |
| referred_id | uuid | YES |
| referral_code | text | NO |
| app_opened_at | timestamp with time zone | YES |
| registered_at | timestamp with time zone | YES |
| first_purchase_at | timestamp with time zone | YES |
| status | text | NO |
| created_at | timestamp with time zone | YES |

### reorder_recommendations

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| item_id | uuid | NO |
| days_of_stock | numeric | YES |
| urgency | text | YES |
| recommended_qty | numeric | YES |
| based_on_days | integer | YES |
| auto_resolved | boolean | YES |
| resolved_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | YES |

### report_schedules

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| report_key | text | NO |
| label | text | NO |
| schedule_type | text | NO |
| time_of_day | text | NO |
| day_of_week | integer | YES |
| day_of_month | integer | YES |
| delivery | ARRAY | NO |
| email_to | text | YES |
| format | text | NO |
| date_range | text | NO |
| is_active | boolean | NO |
| last_run_at | timestamp with time zone | YES |
| next_run_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | NO |
| updated_at | timestamp with time zone | NO |

### role_permissions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| role_name | text | NO |
| permissions | jsonb | NO |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### scale_config

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| primary_mode | text | YES |
| plu_digits | integer | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### scheduled_report_runs

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| schedule_id | uuid | NO |
| report_key | text | NO |
| status | text | NO |
| row_count | integer | YES |
| delivery_log | jsonb | YES |
| error_message | text | YES |
| run_at | timestamp with time zone | NO |

### shrinkage_alerts

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| item_id | uuid | NO |
| alert_date | date | NO |
| expected_qty | numeric | YES |
| actual_qty | numeric | YES |
| variance_pct | numeric | YES |
| acknowledged | boolean | YES |
| acknowledged_by | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| resolved | boolean | YES |
| resolved_by | uuid | YES |
| resolved_at | timestamp with time zone | YES |
| resolution_notes | text | YES |
| product_id | uuid | YES |
| item_name | text | YES |
| status | text | YES |
| theoretical_stock | numeric | YES |
| actual_stock | numeric | YES |
| gap_amount | numeric | YES |
| gap_percentage | numeric | YES |
| possible_reasons | text | YES |
| staff_involved | text | YES |
| shrinkage_percentage | numeric | YES |
| alert_type | text | YES |
| batch_id | uuid | YES |
| expected_weight | numeric | YES |
| actual_weight | numeric | YES |

### smtp_settings

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| host | text | NO |
| port | integer | NO |
| username | text | NO |
| use_ssl | boolean | YES |
| from_name | text | YES |
| from_email | text | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### split_payments

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| transaction_id | uuid | NO |
| payment_method | text | NO |
| amount | numeric | NO |
| amount_tendered | numeric | YES |
| change_given | numeric | YES |
| card_reference | text | YES |
| business_account_id | uuid | YES |
| created_at | timestamp with time zone | YES |

### sponsorships

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| sponsor_name | text | NO |
| event_name | text | NO |
| sponsorship_amount | numeric | NO |
| sponsorship_date | date | NO |
| payment_status | text | NO |
| contact_person | text | YES |
| contact_details | text | YES |
| benefits_provided | text | YES |
| notes | text | YES |
| created_by | uuid | NO |
| created_at | timestamp with time zone | YES |

### staff_awol_records

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| awol_date | date | NO |
| expected_start_time | time without time zone | YES |
| notified_owner_manager | boolean | YES |
| notified_who | text | YES |
| resolution | text | NO |
| written_warning_issued | boolean | YES |
| warning_document_url | text | YES |
| notes | text | YES |
| recorded_by | uuid | NO |
| created_at | timestamp with time zone | YES |

### staff_credit

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| credit_amount | numeric | NO |
| reason | text | NO |
| granted_date | date | NO |
| due_date | date | YES |
| is_paid | boolean | YES |
| paid_date | date | YES |
| granted_by | uuid | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| credit_type | text | YES |
| items_purchased | text | YES |
| repayment_plan | text | YES |
| deduct_from | text | YES |
| status | text | NO |

### staff_documents

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| employee_id | uuid | NO |
| doc_type | text | NO |
| file_name | text | NO |
| file_url | text | NO |
| uploaded_by | uuid | YES |
| uploaded_at | timestamp with time zone | YES |
| notes | text | YES |

### staff_loans

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| loan_amount | numeric | NO |
| interest_rate | numeric | YES |
| term_months | integer | YES |
| monthly_payment | numeric | YES |
| granted_date | date | NO |
| first_payment_date | date | YES |
| is_active | boolean | YES |
| granted_by | uuid | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |

### staff_profiles

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| full_name | text | NO |
| role | text | NO |
| pin_hash | text | YES |
| phone | text | YES |
| hire_date | date | YES |
| pay_frequency | text | NO |
| hourly_rate | numeric | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| email | text | YES |
| id_number | text | YES |
| employment_type | text | YES |
| monthly_salary | numeric | YES |
| max_discount_pct | numeric | YES |
| bank_name | text | YES |
| bank_account | text | YES |
| bank_branch_code | text | YES |
| notes | text | YES |
| max_discount_percent | numeric | NO |
| can_clock_in | boolean | NO |
| uif_exempt | boolean | NO |
| working_days_per_week | integer | NO |

### staff_requests

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| request_type | text | NO |
| status | text | NO |
| amount_requested | numeric | YES |
| amount_approved | numeric | YES |
| advance_reason | text | YES |
| decline_reason | text | YES |
| leave_type | text | YES |
| leave_start_date | date | YES |
| leave_end_date | date | YES |
| days_requested | numeric | YES |
| leave_notes | text | YES |
| leave_decline_reason | text | YES |
| reviewed_by | uuid | YES |
| reviewed_at | timestamp with time zone | YES |
| created_at | timestamp with time zone | YES |

### stock_locations

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| type | text | YES |
| sort_order | integer | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |

### stock_movements

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| item_id | uuid | NO |
| movement_type | text | NO |
| quantity | numeric | NO |
| unit_type | text | YES |
| location_from | uuid | YES |
| location_to | uuid | YES |
| balance_after | numeric | YES |
| reference_id | text | YES |
| reference_type | text | YES |
| reason | text | YES |
| staff_id | uuid | YES |
| photo_url | text | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| metadata | jsonb | YES |

### stock_take_entries

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| session_id | uuid | NO |
| item_id | uuid | NO |
| location_id | uuid | YES |
| expected_quantity | numeric | NO |
| actual_quantity | numeric | YES |
| variance | numeric | YES |
| counted_by | uuid | YES |
| device_id | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### stock_take_sessions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| status | text | NO |
| started_at | timestamp with time zone | YES |
| started_by | uuid | YES |
| approved_at | timestamp with time zone | YES |
| approved_by | uuid | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| rejection_note | text | YES |

### supplier_invoices

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| invoice_number | text | NO |
| supplier_id | uuid | YES |
| invoice_date | date | NO |
| due_date | date | NO |
| line_items | jsonb | YES |
| subtotal | numeric | NO |
| tax_rate | numeric | YES |
| tax_amount | numeric | NO |
| total | numeric | NO |
| status | text | NO |
| payment_date | date | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| received_at | timestamp with time zone | YES |
| received_by | uuid | YES |
| calculation_verified | boolean | YES |
| calculation_errors | jsonb | YES |
| ocr_confidence | numeric | YES |
| ocr_raw_text | text | YES |
| source | text | YES |
| pending_mappings | jsonb | YES |
| mappings_complete | boolean | YES |
| is_opening_balance | boolean | NO |
| amount_paid | numeric | NO |
| balance_due | numeric | YES |

### supplier_item_mappings

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| supplier_id | uuid | YES |
| supplier_description | text | NO |
| description_normalized | text | YES |
| account_code | text | NO |
| inventory_item_id | uuid | YES |
| update_stock | boolean | YES |
| unit_of_measure | text | YES |
| notes | text | YES |
| created_by | uuid | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### supplier_payments

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| supplier_id | uuid | YES |
| invoice_id | uuid | YES |
| payment_date | date | NO |
| amount | numeric | NO |
| payment_method | text | NO |
| bank_reference | text | YES |
| ledger_entry_id | uuid | YES |
| notes | text | YES |
| recorded_by | uuid | YES |
| created_at | timestamp with time zone | NO |

### supplier_price_changes

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| inventory_item_id | uuid | YES |
| supplier_id | uuid | YES |
| old_price | numeric | YES |
| new_price | numeric | YES |
| percentage_increase | numeric | YES |
| suggested_sell_price | numeric | YES |
| status | text | YES |
| created_at | timestamp with time zone | YES |

### suppliers

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| contact_name | text | YES |
| phone | text | YES |
| email | text | YES |
| account_number | text | YES |
| notes | text | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| vat_number | text | YES |
| address | text | YES |
| city | text | YES |
| postal_code | text | YES |
| payment_terms | text | YES |
| bank_name | text | YES |
| bank_account | text | YES |
| bank_branch_code | text | YES |
| bbbee_level | text | YES |

### suspended_transactions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| terminal_id | text | NO |
| cashier_id | uuid | YES |
| cart_json | jsonb | NO |
| customer_note | text | YES |
| customer_id | uuid | YES |
| parked_at | timestamp with time zone | YES |
| expected_collection_time | timestamp with time zone | YES |
| carry_over | boolean | YES |
| carry_over_date | date | YES |
| notification_sent | boolean | YES |
| active | boolean | YES |
| created_at | timestamp with time zone | YES |

### system_config

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| key | text | NO |
| description | text | YES |
| value | jsonb | YES |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### tax_rules

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| percentage | numeric | NO |
| is_active | boolean | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |

### till_sessions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| terminal_id | text | NO |
| opened_by | uuid | NO |
| opened_at | timestamp with time zone | NO |
| opening_float | numeric | NO |
| closed_by | uuid | YES |
| closed_at | timestamp with time zone | YES |
| expected_closing_cash | numeric | YES |
| actual_closing_cash | numeric | YES |
| variance | numeric | YES |
| status | text | NO |
| notes | text | YES |
| created_at | timestamp with time zone | YES |

### timecard_breaks

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| timecard_id | uuid | NO |
| break_start | timestamp with time zone | YES |
| break_end | timestamp with time zone | YES |
| break_duration_minutes | numeric | YES |
| created_at | timestamp with time zone | YES |
| break_type | text | NO |

### timecards

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| staff_id | uuid | NO |
| shift_date | date | NO |
| clock_in | timestamp with time zone | YES |
| clock_out | timestamp with time zone | YES |
| break_minutes | integer | YES |
| break_detail | jsonb | YES |
| total_hours | numeric | YES |
| notes | text | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| employee_id | uuid | YES |
| status | text | NO |
| regular_hours | numeric | YES |
| overtime_hours | numeric | YES |
| sunday_hours | numeric | YES |
| public_holiday_hours | numeric | YES |

### transaction_items

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| transaction_id | uuid | NO |
| inventory_item_id | uuid | YES |
| quantity | numeric | NO |
| unit_price | numeric | NO |
| line_total | numeric | NO |
| created_at | timestamp with time zone | YES |
| cost_price | numeric | YES |
| discount_amount | numeric | YES |
| is_weighted | boolean | YES |
| weight_kg | numeric | YES |
| modifier_selections | jsonb | YES |
| product_name | text | YES |

### transactions

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| created_at | timestamp with time zone | NO |
| total_amount | numeric | NO |
| cost_amount | numeric | YES |
| payment_method | text | YES |
| till_session_id | uuid | YES |
| staff_id | uuid | YES |
| account_id | uuid | YES |
| notes | text | YES |
| vat_amount | numeric | YES |
| receipt_number | text | YES |
| discount_total | numeric | YES |
| loyalty_customer_id | uuid | YES |
| refund_of_transaction_id | uuid | YES |
| is_refund | boolean | YES |
| is_voided | boolean | YES |
| voided_by | uuid | YES |
| voided_at | timestamp with time zone | YES |
| void_reason | text | YES |

### yield_template_cuts

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| template_id | uuid | NO |
| cut_name | text | NO |
| expected_percentage | numeric | NO |
| expected_weight_kg | numeric | YES |
| sort_order | integer | YES |
| created_at | timestamp with time zone | YES |

### yield_templates

| Column | Type | Nullable |
|--------|------|----------|
| id | uuid | NO |
| name | text | NO |
| species | text | NO |
| cuts | jsonb | YES |
| created_at | timestamp with time zone | YES |
| updated_at | timestamp with time zone | YES |
| carcass_type | text | YES |
| template_name | text | YES |

## Foreign keys (public)

| Table | Column | References |
|-------|--------|------------|
| account_awol_records | account_id | business_accounts.id |
| account_awol_records | account_id | business_accounts.id |
| account_awol_records | recorded_by | profiles.id |
| account_awol_records | recorded_by | profiles.id |
| account_transactions | account_id | business_accounts.id |
| account_transactions | account_id | business_accounts.id |
| account_transactions | recorded_by | profiles.id |
| account_transactions | recorded_by | profiles.id |
| announcements | created_by | profiles.id |
| announcements | created_by | profiles.id |
| audit_log | authorised_by | profiles.id |
| audit_log | authorised_by | profiles.id |
| audit_log | staff_id | profiles.id |
| audit_log | staff_id | profiles.id |
| bank_reconciliation_matches | bank_transaction_id | bank_transactions.id |
| bank_reconciliation_matches | bank_transaction_id | bank_transactions.id |
| bank_reconciliation_matches | created_by | profiles.id |
| bank_reconciliation_matches | created_by | profiles.id |
| bank_transactions | created_by | profiles.id |
| bank_transactions | created_by | profiles.id |
| carcass_breakdown_sessions | intake_id | carcass_intakes.id |
| carcass_breakdown_sessions | intake_id | carcass_intakes.id |
| carcass_breakdown_sessions | processed_by | profiles.id |
| carcass_breakdown_sessions | processed_by | profiles.id |
| carcass_breakdown_sessions | template_id | yield_templates.id |
| carcass_breakdown_sessions | template_id | yield_templates.id |
| carcass_cuts | carcass_id | carcass_intakes.id |
| carcass_cuts | carcass_id | carcass_intakes.id |
| carcass_cuts | intake_id | carcass_intakes.id |
| carcass_cuts | intake_id | carcass_intakes.id |
| carcass_intakes | hunter_job_id | hunter_jobs.id |
| carcass_intakes | hunter_job_id | hunter_jobs.id |
| carcass_intakes | supplier_id | suppliers.id |
| carcass_intakes | supplier_id | suppliers.id |
| carcass_intakes | yield_template_id | yield_templates.id |
| carcass_intakes | yield_template_id | yield_templates.id |
| categories | parent_id | categories.id |
| chart_of_accounts | parent_id | chart_of_accounts.id |
| compliance_records | staff_id | staff_profiles.id |
| compliance_records | staff_id | staff_profiles.id |
| compliance_records | verified_by | staff_profiles.id |
| compliance_records | verified_by | staff_profiles.id |
| custom_reward_campaigns | announcement_id | announcements.id |
| custom_reward_campaigns | announcement_id | announcements.id |
| custom_reward_campaigns | created_by | profiles.id |
| custom_reward_campaigns | created_by | profiles.id |
| custom_reward_ingredients | campaign_id | custom_reward_campaigns.id |
| custom_reward_ingredients | campaign_id | custom_reward_campaigns.id |
| custom_reward_orders | campaign_id | custom_reward_campaigns.id |
| custom_reward_orders | campaign_id | custom_reward_campaigns.id |
| custom_reward_orders | customer_id | loyalty_customers.id |
| custom_reward_orders | customer_id | loyalty_customers.id |
| custom_reward_orders | meat_base_id | custom_reward_ingredients.id |
| custom_reward_orders | meat_base_id | custom_reward_ingredients.id |
| custom_reward_orders | spice_profile_id | custom_reward_ingredients.id |
| custom_reward_orders | spice_profile_id | custom_reward_ingredients.id |
| customer_invoices | account_id | business_accounts.id |
| customer_invoices | account_id | business_accounts.id |
| customer_invoices | created_by | profiles.id |
| customer_invoices | created_by | profiles.id |
| customer_invoices | transaction_id | transactions.id |
| customer_invoices | transaction_id | transactions.id |
| customer_recipe_category_assignments | option_id | customer_recipe_category_options.id |
| customer_recipe_category_assignments | option_id | customer_recipe_category_options.id |
| customer_recipe_category_assignments | recipe_id | customer_recipes.id |
| customer_recipe_category_assignments | recipe_id | customer_recipes.id |
| customer_recipe_category_options | type_id | customer_recipe_category_types.id |
| customer_recipe_category_options | type_id | customer_recipe_category_types.id |
| customer_recipe_images | recipe_id | customer_recipes.id |
| customer_recipe_images | recipe_id | customer_recipes.id |
| customer_recipe_ingredients | recipe_id | customer_recipes.id |
| customer_recipe_ingredients | recipe_id | customer_recipes.id |
| customer_recipe_steps | recipe_id | customer_recipes.id |
| customer_recipe_steps | recipe_id | customer_recipes.id |
| customer_recipes | created_by | profiles.id |
| customer_recipes | created_by | profiles.id |
| donations | recorded_by | profiles.id |
| donations | recorded_by | profiles.id |
| dryer_batch_ingredients | batch_id | dryer_batches.id |
| dryer_batch_ingredients | batch_id | dryer_batches.id |
| dryer_batch_ingredients | inventory_item_id | inventory_items.id |
| dryer_batch_ingredients | inventory_item_id | inventory_items.id |
| dryer_batches | input_product_id | inventory_items.id |
| dryer_batches | input_product_id | inventory_items.id |
| dryer_batches | output_product_id | inventory_items.id |
| dryer_batches | output_product_id | inventory_items.id |
| dryer_batches | production_batch_id | production_batches.id |
| dryer_batches | production_batch_id | production_batches.id |
| dryer_batches | recipe_id | recipes.id |
| dryer_batches | recipe_id | recipes.id |
| email_log | invoice_id | customer_invoices.id |
| email_log | invoice_id | customer_invoices.id |
| equipment_register | updated_by | profiles.id |
| equipment_register | updated_by | profiles.id |
| event_sales_history | event_id | event_tags.id |
| event_sales_history | event_id | event_tags.id |
| financial_periods | created_by | profiles.id |
| financial_periods | created_by | profiles.id |
| hunter_job_processes | job_id | hunter_jobs.id |
| hunter_job_processes | job_id | hunter_jobs.id |
| hunter_job_processes | processed_by | profiles.id |
| hunter_job_processes | processed_by | profiles.id |
| hunter_process_materials | process_id | hunter_job_processes.id |
| hunter_process_materials | process_id | hunter_job_processes.id |
| hunter_services | inventory_item_id | inventory_items.id |
| hunter_services | inventory_item_id | inventory_items.id |
| inventory_items | category_id | categories.id |
| inventory_items | category_id | categories.id |
| inventory_items | parent_stock_item_id | inventory_items.id |
| inventory_items | sub_category_id | categories.id |
| inventory_items | sub_category_id | categories.id |
| inventory_items | supplier_id | suppliers.id |
| inventory_items | supplier_id | suppliers.id |
| invoice_line_items | invoice_id | invoices.id |
| invoice_line_items | invoice_id | invoices.id |
| invoices | account_id | business_accounts.id |
| invoices | account_id | business_accounts.id |
| invoices | created_by | staff_profiles.id |
| invoices | created_by | staff_profiles.id |
| invoices | supplier_id | suppliers.id |
| invoices | supplier_id | suppliers.id |
| leave_balances | employee_id | profiles.id |
| leave_balances | employee_id | profiles.id |
| leave_balances | staff_id | staff_profiles.id |
| leave_balances | staff_id | staff_profiles.id |
| leave_history | recorded_by | profiles.id |
| leave_history | recorded_by | profiles.id |
| leave_history | staff_id | staff_profiles.id |
| leave_history | staff_id | staff_profiles.id |
| leave_requests | approved_by | staff_profiles.id |
| leave_requests | approved_by | staff_profiles.id |
| leave_requests | employee_id | profiles.id |
| leave_requests | employee_id | profiles.id |
| leave_requests | staff_id | staff_profiles.id |
| leave_requests | staff_id | staff_profiles.id |
| ledger_entries | account_id | business_accounts.id |
| ledger_entries | account_id | business_accounts.id |
| ledger_entries | created_by | staff_profiles.id |
| ledger_entries | created_by | staff_profiles.id |
| ledger_entries | recorded_by | profiles.id |
| ledger_entries | recorded_by | profiles.id |
| loyalty_customers | auth_uid | auth.users |
| loyalty_notifications | customer_id | loyalty_customers.id |
| loyalty_notifications | customer_id | loyalty_customers.id |
| loyalty_points_log | customer_id | loyalty_customers.id |
| loyalty_points_log | customer_id | loyalty_customers.id |
| loyalty_points_log | staff_id | profiles.id |
| loyalty_points_log | staff_id | profiles.id |
| loyalty_points_log | transaction_id | transactions.id |
| loyalty_points_log | transaction_id | transactions.id |
| modifier_items | inventory_item_id | inventory_items.id |
| modifier_items | inventory_item_id | inventory_items.id |
| modifier_items | linked_item_id | inventory_items.id |
| modifier_items | linked_item_id | inventory_items.id |
| modifier_items | modifier_group_id | modifier_groups.id |
| modifier_items | modifier_group_id | modifier_groups.id |
| online_order_items | inventory_item_id | inventory_items.id |
| online_order_items | inventory_item_id | inventory_items.id |
| online_order_items | order_id | online_orders.id |
| online_order_items | order_id | online_orders.id |
| online_order_print_queue | order_id | online_orders.id |
| online_order_print_queue | order_id | online_orders.id |
| online_orders | customer_id | loyalty_customers.id |
| online_orders | customer_id | loyalty_customers.id |
| online_orders | parked_sale_id | parked_sales.id |
| online_orders | parked_sale_id | parked_sales.id |
| online_product_categories | category_id | categories.id |
| online_product_categories | category_id | categories.id |
| online_product_categories | inventory_item_id | inventory_items.id |
| online_product_categories | inventory_item_id | inventory_items.id |
| online_product_recipes | customer_recipe_id | customer_recipes.id |
| online_product_recipes | customer_recipe_id | customer_recipes.id |
| online_product_recipes | inventory_item_id | inventory_items.id |
| online_product_recipes | inventory_item_id | inventory_items.id |
| online_product_suggestions | source_product_id | inventory_items.id |
| online_product_suggestions | source_product_id | inventory_items.id |
| online_product_suggestions | suggested_product_id | inventory_items.id |
| online_product_suggestions | suggested_product_id | inventory_items.id |
| opening_balances | account_code | chart_of_accounts.code |
| opening_balances | account_code | chart_of_accounts.code |
| opening_balances | recorded_by | profiles.id |
| opening_balances | recorded_by | profiles.id |
| parked_sales | customer_id | loyalty_customers.id |
| parked_sales | customer_id | loyalty_customers.id |
| parked_sales | hunter_job_id | hunter_jobs.id |
| parked_sales | hunter_job_id | hunter_jobs.id |
| payroll_entries | approved_by | staff_profiles.id |
| payroll_entries | approved_by | staff_profiles.id |
| payroll_entries | period_id | payroll_periods.id |
| payroll_entries | period_id | payroll_periods.id |
| payroll_entries | staff_id | staff_profiles.id |
| payroll_entries | staff_id | staff_profiles.id |
| payroll_periods | processed_by | profiles.id |
| payroll_periods | processed_by | profiles.id |
| petty_cash_movements | recorded_by | profiles.id |
| petty_cash_movements | recorded_by | profiles.id |
| petty_cash_movements | till_session_id | till_sessions.id |
| petty_cash_movements | till_session_id | till_sessions.id |
| product_suppliers | inventory_item_id | inventory_items.id |
| product_suppliers | inventory_item_id | inventory_items.id |
| product_suppliers | supplier_id | suppliers.id |
| product_suppliers | supplier_id | suppliers.id |
| production_batch_ingredients | batch_id | production_batches.id |
| production_batch_ingredients | batch_id | production_batches.id |
| production_batch_ingredients | ingredient_id | recipe_ingredients.id |
| production_batch_ingredients | ingredient_id | recipe_ingredients.id |
| production_batch_outputs | batch_id | production_batches.id |
| production_batch_outputs | batch_id | production_batches.id |
| production_batch_outputs | inventory_item_id | inventory_items.id |
| production_batch_outputs | inventory_item_id | inventory_items.id |
| production_batches | output_product_id | inventory_items.id |
| production_batches | output_product_id | inventory_items.id |
| production_batches | parent_batch_id | production_batches.id |
| production_batches | recipe_id | recipes.id |
| production_batches | recipe_id | recipes.id |
| promotion_products | inventory_item_id | inventory_items.id |
| promotion_products | inventory_item_id | inventory_items.id |
| promotion_products | promotion_id | promotions.id |
| promotion_products | promotion_id | promotions.id |
| promotion_suggestions | product_id | inventory_items.id |
| promotion_suggestions | product_id | inventory_items.id |
| purchase_order_lines | inventory_item_id | inventory_items.id |
| purchase_order_lines | inventory_item_id | inventory_items.id |
| purchase_order_lines | purchase_order_id | purchase_orders.id |
| purchase_order_lines | purchase_order_id | purchase_orders.id |
| purchase_orders | created_by | profiles.id |
| purchase_orders | created_by | profiles.id |
| purchase_orders | supplier_id | suppliers.id |
| purchase_orders | supplier_id | suppliers.id |
| purchase_sale_agreement | account_id | business_accounts.id |
| purchase_sale_agreement | account_id | business_accounts.id |
| purchase_sale_agreement | created_by | profiles.id |
| purchase_sale_agreement | created_by | profiles.id |
| purchase_sale_payments | agreement_id | purchase_sale_agreement.id |
| purchase_sale_payments | agreement_id | purchase_sale_agreement.id |
| purchase_sale_payments | recorded_by | profiles.id |
| purchase_sale_payments | recorded_by | profiles.id |
| recipe_ingredients | inventory_item_id | inventory_items.id |
| recipe_ingredients | inventory_item_id | inventory_items.id |
| recipe_ingredients | recipe_id | recipes.id |
| recipe_ingredients | recipe_id | recipes.id |
| recipes | dryer_output_product_id | inventory_items.id |
| recipes | dryer_output_product_id | inventory_items.id |
| recipes | output_product_id | inventory_items.id |
| recipes | output_product_id | inventory_items.id |
| referrals | referred_id | loyalty_customers.id |
| referrals | referred_id | loyalty_customers.id |
| referrals | referrer_id | loyalty_customers.id |
| referrals | referrer_id | loyalty_customers.id |
| reorder_recommendations | item_id | inventory_items.id |
| reorder_recommendations | item_id | inventory_items.id |
| scheduled_report_runs | schedule_id | report_schedules.id |
| scheduled_report_runs | schedule_id | report_schedules.id |
| shrinkage_alerts | acknowledged_by | staff_profiles.id |
| shrinkage_alerts | acknowledged_by | staff_profiles.id |
| shrinkage_alerts | batch_id | production_batches.id |
| shrinkage_alerts | batch_id | production_batches.id |
| shrinkage_alerts | product_id | inventory_items.id |
| shrinkage_alerts | product_id | inventory_items.id |
| shrinkage_alerts | resolved_by | profiles.id |
| shrinkage_alerts | resolved_by | profiles.id |
| split_payments | business_account_id | business_accounts.id |
| split_payments | business_account_id | business_accounts.id |
| split_payments | transaction_id | transactions.id |
| split_payments | transaction_id | transactions.id |
| sponsorships | created_by | profiles.id |
| sponsorships | created_by | profiles.id |
| staff_awol_records | recorded_by | profiles.id |
| staff_awol_records | recorded_by | profiles.id |
| staff_awol_records | staff_id | profiles.id |
| staff_awol_records | staff_id | profiles.id |
| staff_credit | granted_by | profiles.id |
| staff_credit | granted_by | profiles.id |
| staff_credit | staff_id | profiles.id |
| staff_credit | staff_id | profiles.id |
| staff_documents | employee_id | profiles.id |
| staff_documents | employee_id | profiles.id |
| staff_documents | uploaded_by | profiles.id |
| staff_documents | uploaded_by | profiles.id |
| staff_loans | granted_by | profiles.id |
| staff_loans | granted_by | profiles.id |
| staff_loans | staff_id | profiles.id |
| staff_loans | staff_id | profiles.id |
| staff_requests | reviewed_by | profiles.id |
| staff_requests | reviewed_by | profiles.id |
| staff_requests | staff_id | staff_profiles.id |
| staff_requests | staff_id | staff_profiles.id |
| stock_movements | item_id | inventory_items.id |
| stock_movements | item_id | inventory_items.id |
| stock_movements | location_from | stock_locations.id |
| stock_movements | location_from | stock_locations.id |
| stock_movements | location_to | stock_locations.id |
| stock_movements | location_to | stock_locations.id |
| stock_movements | staff_id | profiles.id |
| stock_movements | staff_id | profiles.id |
| stock_take_entries | counted_by | profiles.id |
| stock_take_entries | counted_by | profiles.id |
| stock_take_entries | item_id | inventory_items.id |
| stock_take_entries | item_id | inventory_items.id |
| stock_take_entries | location_id | stock_locations.id |
| stock_take_entries | location_id | stock_locations.id |
| stock_take_entries | session_id | stock_take_sessions.id |
| stock_take_entries | session_id | stock_take_sessions.id |
| stock_take_sessions | approved_by | profiles.id |
| stock_take_sessions | approved_by | profiles.id |
| stock_take_sessions | started_by | profiles.id |
| stock_take_sessions | started_by | profiles.id |
| supplier_invoices | created_by | profiles.id |
| supplier_invoices | created_by | profiles.id |
| supplier_invoices | received_by | profiles.id |
| supplier_invoices | received_by | profiles.id |
| supplier_invoices | supplier_id | suppliers.id |
| supplier_invoices | supplier_id | suppliers.id |
| supplier_item_mappings | account_code | chart_of_accounts.code |
| supplier_item_mappings | account_code | chart_of_accounts.code |
| supplier_item_mappings | created_by | staff_profiles.id |
| supplier_item_mappings | created_by | staff_profiles.id |
| supplier_item_mappings | inventory_item_id | inventory_items.id |
| supplier_item_mappings | inventory_item_id | inventory_items.id |
| supplier_item_mappings | supplier_id | suppliers.id |
| supplier_item_mappings | supplier_id | suppliers.id |
| supplier_payments | invoice_id | supplier_invoices.id |
| supplier_payments | invoice_id | supplier_invoices.id |
| supplier_payments | ledger_entry_id | ledger_entries.id |
| supplier_payments | ledger_entry_id | ledger_entries.id |
| supplier_payments | recorded_by | profiles.id |
| supplier_payments | recorded_by | profiles.id |
| supplier_payments | supplier_id | suppliers.id |
| supplier_payments | supplier_id | suppliers.id |
| suspended_transactions | cashier_id | profiles.id |
| suspended_transactions | cashier_id | profiles.id |
| till_sessions | closed_by | profiles.id |
| till_sessions | closed_by | profiles.id |
| till_sessions | opened_by | profiles.id |
| till_sessions | opened_by | profiles.id |
| timecard_breaks | timecard_id | timecards.id |
| timecard_breaks | timecard_id | timecards.id |
| timecards | employee_id | profiles.id |
| timecards | employee_id | profiles.id |
| timecards | staff_id | staff_profiles.id |
| timecards | staff_id | staff_profiles.id |
| transaction_items | inventory_item_id | inventory_items.id |
| transaction_items | inventory_item_id | inventory_items.id |
| transaction_items | transaction_id | transactions.id |
| transaction_items | transaction_id | transactions.id |
| transactions | account_id | business_accounts.id |
| transactions | account_id | business_accounts.id |
| transactions | loyalty_customer_id | loyalty_customers.id |
| transactions | loyalty_customer_id | loyalty_customers.id |
| transactions | refund_of_transaction_id | transactions.id |
| transactions | staff_id | profiles.id |
| transactions | staff_id | profiles.id |
| transactions | till_session_id | till_sessions.id |
| transactions | till_session_id | till_sessions.id |
| transactions | voided_by | profiles.id |
| transactions | voided_by | profiles.id |
| yield_template_cuts | template_id | yield_templates.id |
| yield_template_cuts | template_id | yield_templates.id |