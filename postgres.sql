-- authorization helper function
CREATE OR REPLACE FUNCTION private.customer_admin()
    RETURNS boolean
    LANGUAGE plpgsql
    set search_path = ''
AS $function$BEGIN
    RETURN
        EXISTS(
            SELECT customerid 
            AS uuid 
            FROM private.customer_user 
            WHERE 
                (userid = (SELECT auth.uid())) AND 
                (
                    customer_user_type = 'Admin'::"private"."customer_user_type" OR 
                    customer_user_type = 'Owner'::"private"."customer_user_type")
        );

    END;$function$
;

-- create business group trigger
CREATE OR REPLACE FUNCTION private.tgfn_after_insert_customer()
 RETURNS trigger
 LANGUAGE plpgsql
 set search_path = ''
 SECURITY DEFINER
AS $function$BEGIN
    INSERT INTO private.customer_user (customerid, userid, customer_user_type) VALUES
    (NEW.customerid, NEW.owner, 'Owner'::"private"."customer_user_type");

    insert into pv_stripe.customers(email, name, description) values
    (NEW.billing_email, NEW.customer, NEW.customerid);
    RETURN NULL;
END;$function$
;

CREATE TRIGGER after_insert_customer AFTER INSERT ON private.customer FOR EACH ROW EXECUTE FUNCTION private.tgfn_after_insert_customer();

-- stripe billing foreign data wrappers

create extension if not exists "wrappers" with schema "extensions";

create foreign data wrapper stripe_wrapper
    handler stripe_fdw_handler
    validator stripe_fdw_validator;

CREATE SERVER stripe_server
FOREIGN DATA WRAPPER stripe_wrapper
OPTIONS (
    api_key '<api_key>',
    api_url 'https://api.stripe.com/v1/'
);

create foreign table "pv_stripe".customers (
    id text,
    email text,
    name text,
    description text,
    created timestamp,
    attrs jsonb
    )
    server stripe_server
    options (
        object 'customers',
        rowid_column 'id'
    );

create foreign table "pv_stripe".invoices (
    id text,
    customer text,
    subscription text,
    status text,
    total bigint, 
    currency text,
    period_start timestamp,
    period_end timestamp,
    attrs jsonb
    )
    server stripe_server
    options (
        object 'invoices'
    );

create foreign table "pv_stripe".subscriptions (
    id text,
    customer text,
    currency text,
    current_period_start timestamp,
    current_period_end timestamp,
    attrs jsonb
    )
    server stripe_server
    options (
        object 'subscriptions',
        rowid_column 'id'
    );