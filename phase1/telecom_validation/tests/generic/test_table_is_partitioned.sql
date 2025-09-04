-- Test to validate that a table has partitioning enabled in its schema
-- Usage: {{ test_table_is_partitioned(model) }}

{% test table_is_partitioned(model) %}

    -- Check if table has partitioning by looking for partition information
    with partition_check as (
        select count(*) as partition_entries
        from `{{ model.database }}.{{ model.schema }}.INFORMATION_SCHEMA.PARTITIONS`
        where table_name = '{{ model.identifier }}'
    )
    
    select partition_entries
    from partition_check
    where partition_entries = 0  -- Fail if no partition entries found

{% endtest %}