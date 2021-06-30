policy "cis-v1.30" {
  description = "GCP CIS V1.e0 Policy"
  configuration {
    provider "gcp" {
      version = ">= 0.4.11"
    }
  }

  policy "gcp-cis-section-1" {
    description = "GCP CIS Section 1"

    query "1.1" {
      description = "GCP CIS 1.1 Ensure that corporate login credentials are used (Automated)"
      query = <<EOF
      SELECT "needs to list folders and organizations which is currently not supported"
    EOF
    }

    query "1.2" {
      description = "GCP CIS 1.2 Ensure that multi-factor authentication is enabled for all non-service accounts (Manual)"
      query = file("queries/manual.sql")
    }

    query "1.3" {
      description = "GCP CIS 1.3 Ensure that Security Key Enforcement is enabled for all admin accounts (Manual)"
      query = file("queries/manual.sql")
    }

    query "1.4" {
      description = "GCP CIS 1.4 Ensure that there are only GCP-managed service account keys for each service account (Automated)"
      query = <<EOF
      SELECT project_id , gisa.id AS "account_id", gisak.id AS "key_id", gisak."key_type"
      FROM gcp_iam_service_accounts gisa
      JOIN gcp_iam_service_account_keys gisak ON
      gisa.id = gisak.service_account_id
      WHERE gisa.email LIKE '%iam.gserviceaccount.com'
      AND gisak."key_type" = 'USER_MANAGED';
    EOF
    }

    query "1.5" {
      description = "GCP CIS 1.5 Ensure that Service Account has no Admin privileges (Automated)"
      query = <<EOF
      WITH project_policy_roles AS ( SELECT project_id, jsonb_array_elements(p.policy -> 'bindings') AS binding
      FROM gcp_resource_manager_projects p ), role_members AS ( SELECT project_id, binding ->> 'role' AS "role", jsonb_array_elements_text(binding -> 'members') AS MEMBER
      FROM project_policy_roles ) SELECT project_id , "role", MEMBER
      FROM role_members
      WHERE ("role" IN ( 'roles/editor', 'roles/owner')
          OR "role" LIKE ANY (ARRAY['%Admin', '%admin']))
      AND "member" LIKE 'serviceAccount:%';
    EOF
    }

    query "1.6" {
      description = "GCP CIS 1.6 Ensure that IAM users are not assigned the Service Account User or Service Account Token Creator roles at project level (Automated)"
      query = <<EOF
      WITH project_policy_roles AS ( SELECT project_id, jsonb_array_elements(p.policy -> 'bindings') AS binding
      FROM gcp_resource_manager_projects p ), role_members AS ( SELECT project_id, binding ->> 'role' AS "role", jsonb_array_elements_text(binding -> 'members') AS MEMBER
      FROM project_policy_roles ) SELECT project_id , "role", MEMBER
      FROM role_members
      WHERE "role" IN ( 'roles/iam.serviceAccountUser', 'roles/iam.serviceAccountTokenCreator')
      AND "member" LIKE 'user:%';
    EOF
    }

    query "1.7" {
      description = "GCP CIS 1.7 Ensure user-managed/external keys for service accounts are rotated every 90 days or less (Automated)"
      query = <<EOF
      SELECT project_id , gisa.id AS "account_id", gisak.id AS "key_id", gisak.valid_after_time
      FROM gcp_iam_service_accounts gisa
      JOIN gcp_iam_service_account_keys gisak ON
      gisa.id = gisak.service_account_id
      WHERE gisa.email LIKE '%iam.gserviceaccount.com'
      AND DATE_PART('day', CURRENT_DATE - gisak.valid_after_time ) > 90
    EOF
    }

    query "1.8" {
      description = "GCP CIS 1.8 Ensure that Separation of duties is enforced while assigning service account related roles to users (Manual)"
      query = <<EOF
      WITH project_policy_roles AS ( SELECT project_id, jsonb_array_elements(p.policy -> 'bindings') AS binding
      FROM gcp_resource_manager_projects p ), role_members AS ( SELECT project_id, binding ->> 'role' AS "role", jsonb_array_elements_text(binding -> 'members') AS MEMBER
      FROM project_policy_roles ) SELECT project_id , "role", MEMBER
      FROM role_members
      WHERE "role" IN ( 'roles/iam.serviceAccountAdmin', 'roles/iam.serviceAccountUser')
      AND "member" LIKE 'user:%';
    EOF
    }

    query "1.9" {
      description = "GCP CIS 1.9 Ensure that Cloud KMS cryptokeys are not anonymously or publicly accessible (Automated)"
      query = <<EOF
       SELECT "TODO";
    EOF
    }

    query "1.10" {
      description = "GCP CIS 1.10 Ensure KMS encryption keys are rotated within a period of 90 days (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_kms_keyring_crypto_keys gkkck
        WHERE (rotation_period LIKE '%s'
            AND REPLACE(rotation_period, 's', '')::NUMERIC > 7776000)
        OR (rotation_period LIKE '%h'
            AND REPLACE(rotation_period, 'h', '')::NUMERIC > 2160)
        OR (rotation_period LIKE '%m'
            AND REPLACE(rotation_period, 'm', '')::NUMERIC > 129600)
        OR (rotation_period LIKE '%d'
            AND REPLACE(rotation_period, 'd', '')::NUMERIC > 90)
        OR DATE_PART('day', CURRENT_DATE - next_rotation_time ) > 90 ;
    EOF
    }

    query "1.11" {
      description = "GCP CIS 1.11 Ensure that Separation of duties is enforced while assigning KMS related roles to users (Automated)"
      query = <<EOF
        SELECT "TODO";
    EOF
    }

    query "1.12" {
      description = "GCP CIS 1.12 Ensure API keys are not created for a project (Manual)"
      query = file("queries/manual.sql")
    }

    query "1.13" {
      description = "GCP CIS 1.13 Ensure API keys are restricted to use by only specified Hosts and Apps (Manual)"
      query = file("queries/manual.sql")
    }

    query "1.14" {
      description = "GCP CIS 1.14 Ensure API keys are restricted to only APIs that application needs access (Manual)"
      query = file("queries/manual.sql")
    }

    query "1.15" {
      description = "GCP CIS 1.15 Ensure API keys are rotated every 90 days (Manual)"
      query = file("queries/manual.sql")
    }
  }

  policy "gcp-cis-section-2" {
    description = "GCP CIS Section 2"

    query "2.1" {
      description = "GCP CIS 2.1 Ensure that Cloud Audit Logging is configured properly across all services and all users from a project (Automated)"
      query = <<EOF
        SELECT "TODO";
    EOF
    }

    query "2.2" {
      description = "GCP CIS 2.2 Ensure that sinks are configured for all log entries (Automated)"
      query = <<EOF
        WITH found_sinks AS (SELECT count(*) AS configured_sinks
        FROM gcp_logging_sinks gls
        WHERE gls.FILTER = '') SELECT 'no sinks for all log entries configured' AS description
        FROM found_sinks
        WHERE configured_sinks = 0;
    EOF
    }

    query "2.3" {
      description = "GCP CIS 2.3 Ensure that retention policies on log buckets are configured using Bucket Lock (Automated)"
      query = <<EOF
        SELECT gls.project_id, gls.id AS "sink_id", gsb.id AS "bucket_id", gsb.retention_policy_is_locked, gsb.retention_policy_retention_period, gls.destination
        FROM gcp_logging_sinks gls
        JOIN gcp_storage_buckets gsb ON
        gsb.name = REPLACE (gls.destination, 'storage.googleapis.com/', '')
        WHERE gls.destination LIKE 'storage.googleapis.com/%'
        AND ( gsb.retention_policy_is_locked = FALSE
	      OR gsb.retention_policy_retention_period = 0)
    EOF
    }

    query "2.4" {
      description = "GCP CIS 2.4 Ensure log metric filter and alerts exist for project ownership assignments/changes (Automated)"
      query = <<EOF
        WITH found_alerts AS (SELECT COUNT(*) AS "alerts"
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*(\s*protoPayload.serviceName\s*=\s*"cloudresourcemanager.googleapis.com"\s*)\s*AND\s*(\s*ProjectOwnership\s*OR\s*projectOwnerInvitee\s*)\s*OR\s*(\s*protoPayload.serviceData.policyDelta.bindingDeltas.action\s*=\s*"REMOVE"\s*AND\s*protoPayload.serviceData.policyDelta.bindingDeltas.role\s*=\s*"roles/owner"\s*)\s*OR\s*(\s*protoPayload.serviceData.policyDelta.bindingDeltas.action\s*=\s*"ADD"\s*AND\s*protoPayload.serviceData.policyDelta.bindingDeltas.role\s*=\s*"roles/owner"\s*)\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.5" {
      description = "GCP CIS 2.5 Ensure that the log metric filter and alerts exist for Audit Configuration changes (Automated)"
      query = <<EOF
        WITH found_alerts AS ( SELECT count(*) AS alerts
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*protoPayload.methodName\s*=\s*"SetIamPolicy"\s*AND\s*protoPayload.serviceData.policyDelta.auditConfigDeltas:*\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.6" {
      description = "GCP CIS 2.6 Ensure that the log metric filter and alerts exist for Custom Role changes (Automated)"
      query = <<EOF
        WITH found_alerts AS ( SELECT count(*) AS alerts
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*resource.type\s*=\s*"iam_role"\s*AND\s*protoPayload.methodName\s*=\s*"google.iam.admin.v1.CreateRole"\s*OR\s*protoPayload.methodName\s*=\s*"google.iam.admin.v1.DeleteRole"\s*OR\s*protoPayload.methodName\s*=\s*"google.iam.admin.v1.UpdateRole"\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.7" {
      description = "GCP CIS 2.7 Ensure that the log metric filter and alerts exist for VPC Network Firewall rule changes (Automated)"
      query = <<EOF
        WITH found_alerts AS ( SELECT count(*) AS alerts
          FROM gcp_monitoring_alert_policies gmap
          JOIN gcp_monitoring_alert_policy_conditions gmapc ON
          gmap.id = gmapc.alert_policy_id
          JOIN gcp_logging_metrics glm ON
          gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
          AND gmap.enabled = TRUE
          AND glm."filter" ~ '\s*resource.type\s*=\s*"gce_firewall_rule"\s*AND\s*protoPayload.methodName\s*=\s*"v1.compute.firewalls.patch"\s*OR\s*protoPayload.methodName\s*=\s*"v1.compute.firewalls.insert"\s*')
          SELECT 'there are no alrerts configured' AS description
          FROM found_alerts
          WHERE alerts = 0;
    EOF
    }

    query "2.8" {
      description = "GCP CIS 2.8 Ensure that the log metric filter and alerts exist for VPC network route changes (Automated)"
      query = <<EOF
        WITH found_alerts AS ( SELECT count(*) AS alerts
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*resource.type\s*=\s*"gce_route"\s*AND\s*protoPayload.methodName\s*=\s*"beta.compute.routes.patch"\s*OR\s*protoPayload.methodName\s*=\s*"beta.compute.routes.insert"\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.9" {
      description = "GCP CIS 2.9 Ensure that the log metric filter and alerts exist for VPC network changes (Automated)"
      query = <<EOF
        WITH found_alerts AS (SELECT count(*) AS alerts
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*resource.type\s*=\s*gce_network\s*AND\s*protoPayload.methodName\s*=\s*"beta.compute.networks.insert"\s*OR\s*protoPayload.methodName\s*=\s*"beta.compute.networks.patch"\s*OR\s*protoPayload.methodName\s*=\s*"v1.compute.networks.delete"\s*OR\s*protoPayload.methodName\s*=\s*"v1.compute.networks.removePeering"\s*OR\s*protoPayload.methodName\s*=\s*"v1.compute.networks.addPeering"\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.10" {
      description = "GCP CIS 2.10 Ensure that the log metric filter and alerts exist for Cloud Storage IAM permission changes (Automated)"
      query = <<EOF
        WITH found_alerts AS (SELECT count(*) AS alerts
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" ~ '\s*resource.type\s*=\s*gcs_bucket\s*AND\s*protoPayload.methodName\s*=\s*"storage.setIamPermissions"\s*')
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.11" {
      description = "GCP CIS 2.11 Ensure that the log metric filter and alerts exist for SQL instance configuration changes (Automated)"
      query = <<EOF
        WITH found_alerts AS (SELECT *
        FROM gcp_monitoring_alert_policies gmap
        JOIN gcp_monitoring_alert_policy_conditions gmapc ON
        gmap.id = gmapc.alert_policy_id
        JOIN gcp_logging_metrics glm ON
        gmapc.threshold_filter LIKE '%metric.type="' || glm.metric_descriptor_type || '"%'
        AND gmap.enabled = TRUE
        AND glm."filter" = 'protoPayload.methodName="cloudsql.instances.update"';)
        SELECT 'there are no alrerts configured' AS description
        FROM found_alerts
        WHERE alerts = 0;
    EOF
    }

    query "2.12" {
      description = "GCP CIS 2.12 Ensure that Cloud DNS logging is enabled for all VPC networks (Automated)"
      query = <<EOF
        SELECT gcn.id, gcn.project_id , gcn.name AS network_name, gdp.name AS policy_network_name
        FROM gcp_compute_networks gcn
        JOIN gcp_dns_policy_networks gdpn ON
        gcn.self_link = REPLACE(gdpn.network_url, 'compute.googleapis', 'www.googleapis')
        JOIN gcp_dns_policies gdp ON
        gdp.id = gdpn.policy_id
        WHERE gdp.enable_logging = FALSE;
    EOF
    }
  }

  policy "gcp-cis-section-3" {
    description = "GCP CIS Section 3"

    query "3.1" {
      description = "GCP CIS 3.1 Ensure that the default network does not exist in a project (Automated)"
      query = <<EOF
        SELECT project_id , name, self_link
        FROM gcp_compute_networks gcn
        WHERE name = 'default';
    EOF
    }

    query "3.2" {
      description = "GCP CIS 3.2 Ensure legacy networks do not exist for a project (Automated)"
      query = <<EOF
        SELECT project_id , name, self_link , auto_create_subnetworks
        FROM gcp_compute_networks gcn
        WHERE auto_create_subnetworks = FALSE;
    EOF
    }

    query "3.4" {
      description = "GCP CIS 3.4 Ensure that RSASHA1 is not used for the key-signing key in Cloud DNS DNSSEC (Manual)"
      query = <<EOF
        SELECT gdmz.id, gdmz.project_id, gdmz.dns_name , gdmzdcdks."key_type" , gdmzdcdks.algorithm
        FROM gcp_dns_managed_zones gdmz
        JOIN gcp_dns_managed_zone_dnssec_config_default_key_specs gdmzdcdks ON
        gdmz.id = gdmzdcdks.managed_zone_id
        WHERE gdmzdcdks."key_type" = 'keySigning'
        AND gdmzdcdks.algorithm = 'rsasha1';
    EOF
    }

    query "3.5" {
      description = "GCP CIS 3.5 Ensure that RSASHA1 is not used for the zone-signing key in Cloud DNS DNSSEC (Manual)"
      query = <<EOF
        SELECT gdmz.id, gdmz.project_id, gdmz.dns_name , gdmzdcdks."key_type" , gdmzdcdks.algorithm
        FROM gcp_dns_managed_zones gdmz
        JOIN gcp_dns_managed_zone_dnssec_config_default_key_specs gdmzdcdks ON
        gdmz.id = gdmzdcdks.managed_zone_id
        WHERE gdmzdcdks."key_type" = 'zoneSigning'
        AND gdmzdcdks.algorithm = 'rsasha1'
    EOF
    }

    query "3.6" {
      description = "GCP CIS 3.6 Ensure that SSH access is restricted from the internet (Automated)"
      query = <<EOF
        SELECT gcf.id, project_id , name , network
        FROM gcp_compute_firewalls gcf
        JOIN gcp_compute_firewall_allowed gcfa ON
        gcf.id = gcfa.firewall_id
        JOIN ( SELECT id, Count(*) > 0 AS in_port_range
        FROM ( SELECT id, Split_part(p, '-', 1) :: integer AS range_start, split_part(p, '-', 2) :: integer AS range_end
        FROM ( SELECT id, UNNEST(ports) AS p
        FROM gcp_compute_firewall_allowed) AS f
        WHERE p ~ '^[0-9]+(-[0-9]+)$') AS s
        WHERE 22 BETWEEN range_start AND range_end
        GROUP BY id ) AS ff ON
        gcfa.id = ff.id
        WHERE gcf.direction = 'INGRESS'
        AND ( gcfa.ip_protocol = 'tcp'
            OR gcfa.ip_protocol = 'all' )
        AND (CARDINALITY(gcfa.ports) = 0
            OR '22' = ANY (gcfa.ports)
                OR ff.in_port_range
                OR gcfa.ports IS NULL )
        AND '0.0.0.0/0' = ANY (gcf.source_ranges);
    EOF
    }

    query "3.7" {
      description = "GCP CIS 3.7 Ensure that RDP access is restricted from the Internet (Automated)"
      query = <<EOF
        SELECT gcf.id, project_id , name , network
        FROM gcp_compute_firewalls gcf
        JOIN gcp_compute_firewall_allowed gcfa ON
        gcf.id = gcfa.firewall_id
        JOIN ( SELECT id, Count(*) > 0 AS in_port_range
        FROM ( SELECT id, Split_part(p, '-', 1) :: integer AS range_start, split_part(p, '-', 2) :: integer AS range_end
        FROM ( SELECT id, UNNEST(ports) AS p
        FROM gcp_compute_firewall_allowed) AS f
        WHERE p ~ '^[0-9]+(-[0-9]+)$') AS s
        WHERE 3986 BETWEEN range_start AND range_end
        GROUP BY id ) AS ff ON
        gcfa.id = ff.id
        WHERE gcf.direction = 'INGRESS'
        AND ( gcfa.ip_protocol = 'tcp'
            OR gcfa.ip_protocol = 'all' )
        AND (CARDINALITY(gcfa.ports) = 0
            OR '3389' = ANY (gcfa.ports)
                OR ff.in_port_range
                OR gcfa.ports IS NULL )
        AND '0.0.0.0/0' = ANY (gcf.source_ranges);
        --cis 3.8 Ensure that VPC Flow Logs is enabled for every subnet in a VPC Network (Automated)
         SELECT gcn.id, gcn.project_id, gcn.self_link AS network, gcs.self_link AS subnetwork, gcs.enable_flow_logs
        FROM gcp_compute_networks gcn
        JOIN gcp_compute_subnetworks gcs ON
        gcn.self_link = gcs.network
        WHERE gcs.enable_flow_logs = FALSE;
    EOF
    }

    query "3.8" {
      description = "GCP CIS 3.8 Ensure that VPC Flow Logs is enabled for every subnet in a VPC Network (Automated)"
      query = <<EOF
        SELECT gcn.id, gcn.project_id, gcn.self_link AS network, gcs.self_link AS subnetwork, gcs.enable_flow_logs
        FROM gcp_compute_networks gcn
        JOIN gcp_compute_subnetworks gcs ON
        gcn.self_link = gcs.network
        WHERE gcs.enable_flow_logs = FALSE;
    EOF
    }

    query "3.9" {
      description = "GCP CIS 3.9 Ensure no HTTPS or SSL proxy load balancers permit SSL policies with weak cipher suites (Manual)"
      query = <<EOF
        SELECT gctsp.id, gctsp.project_id, gctsp.name, gctsp.ssl_policy, 'wrong policy' AS reason
        FROM gcp_compute_target_https_proxies gctsp
        WHERE ssl_policy NOT LIKE 'https://www.googleapis.com/compute/v1/projects/%/global/sslPolicies/%'
        UNION ALL SELECT gctsp.id, gctsp.project_id, gctsp.name, gctsp.ssl_policy, 'insecure policy config' AS reason
        FROM gcp_compute_target_https_proxies gctsp
        JOIN gcp_compute_ssl_policies p ON
        gctsp.ssl_policy = p.self_link
        WHERE gctsp.ssl_policy LIKE 'https://www.googleapis.com/compute/v1/projects/%/global/sslPolicies/%'
        AND ((p.profile = 'MODERN'
        AND p.min_tls_version != 'TLS_1_2')
        OR (p.profile = 'CUSTOM'
        AND ARRAY ['TLS_RSA_WITH_AES_128_GCM_SHA256' , 'TLS_RSA_WITH_AES_256_GCM_SHA384' , 'TLS_RSA_WITH_AES_128_CBC_SHA' , 'TLS_RSA_WITH_AES_256_CBC_SHA', 'TLS_RSA_WITH_3DES_EDE_CBC_SHA'] @> p.enabled_features )
        OR (p.profile = 'COMPATIBLE'));
    EOF
    }

    query "3.10" {
      description = "GCP CIS3.10 Ensure Firewall Rules for instances behind Identity Aware Proxy (IAP) only allow the traffic from Google Cloud Loadbalancer (GCLB) Health Check and Proxy Addresses (Manual)"
      query = <<EOF
        SELECT gcf.id, count(gcfa) AS allow_rules
        FROM gcp_compute_firewalls gcf
        JOIN gcp_compute_firewall_allowed gcfa ON
        gcf.id = gcfa.firewall_id
        WHERE NOT ARRAY ['35.191.0.0/16', '130.211.0.0/22'] <@ gcf.source_ranges
        GROUP BY gcf.id
        HAVING count(gcfa.*) > 0;
    EOF
    }
  }

  policy "gcp-cis-section-4" {
    description = "GCP CIS Section 4"

    query "4.1" {
      description = "GCP CIS 4.1 Ensure that instances are not configured to use the default service account (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_instances gci
        JOIN gcp_compute_instance_service_accounts gcisa ON
        gci.id = gcisa.instance_id
        WHERE gci."name" NOT LIKE 'gke-'
        AND gcisa.email = (SELECT default_service_account
        FROM gcp_compute_projects
        WHERE project_id = gci.project_id);
    EOF
    }

    query "4.2" {
      description = "GCP CIS 4.2 Ensure that instances are not configured to use the default service account with full access to all Cloud APIs (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_instances gci
        JOIN gcp_compute_instance_service_accounts gcisa ON
        gci.id = gcisa.instance_id
        WHERE gcisa.email = (SELECT default_service_account
        FROM gcp_compute_projects
        WHERE project_id = gci.project_id)
        AND 'https://www.googleapis.com/auth/cloud-platform' IN gcisa.scopes;
    EOF
    }

    query "4.3" {
      description = "GCP CIS 4.3 Ensure \"Block Project-wide SSH keys\" is enabled for VM instances (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_instances
        WHERE metadata_items ->> 'block-project-ssh-keys' IS NULL
        OR metadata_items ->> 'block-project-ssh-keys' != 'true';
    EOF
    }

    query "4.4" {
      description = "GCP CIS 4.4 Ensure oslogin is enabled for a Project (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_projects
        WHERE common_instance_metadata_items ->> 'enable-oslogin' IS NULL
        OR common_instance_metadata_items ->> 'enable-oslogin' != 'true';
    EOF
    }

    query "4.5" {
      description = "GCP CIS 4.5 Ensure 'Enable connecting to serial ports' is not enabled for VM Instance (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_instances
        WHERE metadata_items ->> 'serial-port-enable' = 'true'
        OR metadata_items ->> 'serial-port-enable' = '1';
    EOF
    }

    query "4.6" {
      description = "GCP CIS 4.6 Ensure that IP forwarding is not enabled on Instances (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_instances gci
        WHERE can_ip_forward = TRUE;
    EOF
    }

    query "4.7" {
      description = "GCP CIS 4.7 Ensure VM disks for critical VMs are encrypted with Customer-Supplied Encryption Keys (CSEK) (Automated)"
      query = <<EOF
        SELECT *
        FROM gcp_compute_disks gcd
        WHERE disk_encryption_key_sha256 !~ '^([A-Za-z0-9+\/]{4})*([A-Za-z0-9+\/]{4}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}==)$'
    EOF
    }


    query "4.8" {
      description = "GCP CIS 4.8 Ensure Compute instances are launched with Shielded VM enabled (Automated)"
      query = <<EOF
        SELECT project_id , gci."name"
        FROM gcp_compute_instances gci
        WHERE shielded_instance_config_enable_integrity_monitoring = FALSE
        OR shielded_instance_config_enable_vtpm = FALSE;
    EOF
    }

    query "4.9" {
      description = "GCP CIS 4.9 Ensure that Compute instances do not have public IP addresses (Automated)"
      query = <<EOF
        SELECT project_id , gci."name"
        FROM gcp_compute_instances gci
        JOIN gcp_compute_instance_network_interfaces gcini ON
        gci.id = gcini.instance_id
        JOIN gcp_compute_instance_network_interface_access_configs gciniac ON
        gcini.id = gciniac.instance_network_interface_id
        WHERE gci."name" NOT LIKE "gke-%"
        GROUP BY project_id , gci."name"
        HAVING count(gciniac.*) > 0;
    EOF
    }

    query "4.10" {
      description = "GCP CIS 4.10 Ensure that App Engine applications enforce HTTPS connections (Manual)"
      query = file("queries/manual.sql")
    }

    query "4.11" {
      description = "GCP CIS 4.11 Ensure that Compute instances have Confidential Computing enabled (Automated)"
      query = <<EOF
        SELECT project_id , "name"
        FROM gcp_compute_instances gci
        WHERE confidential_instance_config_enable_confidential_compute = FALSE;
    EOF
    }
  }

  policy "gcp-cis-section-5" {
    description = "GCP CIS Section 5"

    query "5.1" {
      description = "GCP CIS 5.1 Ensure that Cloud Storage bucket is not anonymously or publicly accessible (Automated)"
      query = <<EOF
        SELECT project_id , b."name"
        FROM gcp_storage_buckets b
        JOIN gcp_storage_bucket_policies p ON
        b.id = p.bucket_id
        JOIN gcp_storage_bucket_policy_bindings pb ON
        p.id = pb.bucket_policy_id
        WHERE array_to_string(pb.members, ',') LIKE '%allUsers%'
        OR array_to_string(pb.members, ',') LIKE '%allAuthenticatedUsers%'
        GROUP BY project_id , b."name";
    EOF
    }

    query "5.2" {
      description = "GCP CIS 5.2 Ensure that Cloud Storage buckets have uniform bucket-level access enabled (Automated)"
      query = <<EOF
        SELECT project_id, name
        FROM gcp_storage_buckets
        WHERE iam_configuration_uniform_bucket_level_access_enabled = FALSE;
    EOF
    }
  }

  policy "gcp-cis-section-6" {
    description = "GCP CIS Section 6"

    query "6.1.1" {
      description = "GCP CIS 6.1.1 Ensure that a MySQL database instance does not allow anyone to connect with administrative privileges (Automated)"
      query = file("queries/manual.sql")
    }

    query "6.1.2" {
      description = "GCP CIS 6.1.2 Ensure 'skip_show_database' database flag for Cloud SQL Mysql instance is set to 'on' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'MYSQL%'
        AND (settings_database_flags ->> 'skip_show_database' != 'on'
            OR settings_database_flags ->> 'skip_show_database' IS NULL);
    EOF
    }

    query "6.1.3" {
      description = "GCP CIS 6.1.3 Ensure that the 'local_infile' database flag for a Cloud SQL Mysql instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'MYSQL%'
        AND (settings_database_flags ->> 'local_infile' != 'off'
            OR settings_database_flags ->> 'local_infile' IS NULL);
    EOF
    }

    query "6.2.1" {
      description = "GCP CIS 6.2.1 Ensure that the 'log_checkpoints' database flag for Cloud SQL PostgreSQL instance is set to 'on' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_checkpoints' != 'on'
            OR settings_database_flags ->> 'log_checkpoints' IS NULL);
    EOF
    }

    query "6.2.2" {
      description = "GCP CIS 6.2.2 Ensure 'log_error_verbosity' database flag for Cloud SQL PostgreSQL instance is set to 'DEFAULT' or stricter (Manual)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_error_verbosity' NOT IN('default', 'terse')
            OR settings_database_flags ->> 'log_error_verbosity' IS NULL);
    EOF
    }

    query "6.2.3" {
      description = "GCP CIS 6.2.3 Ensure that the 'log_connections' database flag for Cloud SQL PostgreSQL instance is set to 'on' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_connections' != 'on'
            OR settings_database_flags ->> 'log_connections' IS NULL);
    EOF
    }

    query "6.2.4" {
      description = "GCP CIS 6.2.4 Ensure that the 'log_disconnections' database flag for Cloud SQL PostgreSQL instance is set to 'on' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_disconnections' != 'on'
            OR settings_database_flags ->> 'log_disconnections' IS NULL);
    EOF
    }

    query "6.2.5" {
      description = "GCP CIS 6.2.5 Ensure 'log_duration' database flag for Cloud SQL PostgreSQL instance is set to 'on' (Manual)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_duration' != 'on'
            OR settings_database_flags ->> 'log_duration' IS NULL);
    EOF
    }

    query "6.2.6" {
      description = "GCP CIS 6.2.6 Ensure that the 'log_lock_waits' database flag for Cloud SQL PostgreSQL instance is set to 'on' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_lock_waits' != 'on'
            OR settings_database_flags ->> 'log_lock_waits' IS NULL);
    EOF
    }

    query "6.2.7" {
      description = "GCP CIS 6.2.7 Ensure 'log_statement' database flag for Cloud SQL PostgreSQL instance is set appropriately (Manual)"
      query = file("queries/manual.sql")
    }

    query "6.2.8" {
      description = "GCP CIS 6.2.8 Ensure 'log_hostname' database flag for Cloud SQL PostgreSQL instance is set appropriately (Automated)"
      //todo check what is "set appropriately"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_hostname' != 'off'
            OR settings_database_flags ->> 'log_hostname' IS NULL);
    EOF
    }

    query "6.2.9" {
      description = "GCP CIS 6.2.9 Ensure 'log_parser_stats' database flag for Cloud SQL PostgreSQL instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_parser_stats' != 'off'
            OR settings_database_flags ->> 'log_parser_stats' IS NULL);
    EOF
    }

    query "6.2.10" {
      description = "GCP CIS 6.2.10 Ensure 'log_planner_stats' database flag for Cloud SQL PostgreSQL instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_planner_stats' != 'off'
            OR settings_database_flags ->> 'log_planner_stats' IS NULL);
    EOF
    }

    query "6.2.11" {
      description = "GCP CIS 6.2.11 Ensure 'log_executor_stats' database flag for Cloud SQL PostgreSQL instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_executor_stats' != 'off'
            OR settings_database_flags ->> 'log_executor_stats' IS NULL);
    EOF
    }

    query "6.2.12" {
      description = "GCP CIS 6.2.12 Ensure 'log_statement_stats' database flag for Cloud SQL PostgreSQL instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_statement_stats' != 'off'
            OR settings_database_flags ->> 'log_statement_stats' IS NULL);
    EOF
    }

    query "6.2.13" {
      description = "GCP CIS 6.2.13 Ensure that the 'log_min_messages' database flag for Cloud SQL PostgreSQL instance is set appropriately (Manual)"
      query = file("queries/manual.sql")
    }

    query "6.2.14" {
      description = "GCP CIS 6.2.14 Ensure 'log_min_error_statement' database flag for Cloud SQL PostgreSQL instance is set to 'Error' or stricter (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_min_error_statement' NOT IN('error', 'log', 'fatal', 'panic')
            OR settings_database_flags ->> 'log_min_error_statement' IS NULL);
    EOF
    }

    query "6.2.15" {
      description = "GCP CIS 6.2.15 Ensure that the 'log_temp_files' database flag for Cloud SQL PostgreSQL instance is set to '0' (on) (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_temp_files' != '0'
            OR settings_database_flags ->> 'log_temp_files' IS NULL);
    EOF
    }

    query "6.2.16" {
      description = "GCP CIS 6.2.16 Ensure that the 'log_min_duration_statement' database flag for Cloud SQL PostgreSQL instance is set to '-1' (disabled) (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'POSTGRES%'
        AND (settings_database_flags ->> 'log_min_duration_statement' != '-1'
            OR settings_database_flags ->> 'log_min_duration_statement' IS NULL);
    EOF
    }

    query "6.3.1" {
      description = "GCP CIS 6.3.1 Ensure 'external scripts enabled' database flag for Cloud SQL SQL Server instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND (settings_database_flags ->> 'external scripts enabled' != 'off'
            OR settings_database_flags ->> 'external scripts enabled' IS NULL);
    EOF
    }

    query "6.3.2" {
      description = "GCP CIS 6.3.2 Ensure that the 'cross db ownership chaining' database flag for Cloud SQL SQL Server instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND (settings_database_flags ->> 'cross db ownership chaining' != 'off'
            OR settings_database_flags ->> 'cross db ownership chaining' IS NULL);
    EOF
    }

    query "6.3.3" {
      description = "GCP CIS 6.3.3 Ensure 'user connections' database flag for Cloud SQL SQL Server instance is set as appropriate (Automated)"
      //todo check what is appropriate
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND settings_database_flags ->> 'user connections' IS NULL;
    EOF
    }

    query "6.3.4" {
      description = "GCP CIS 6.3.4 Ensure 'user options' database flag for Cloud SQL SQL Server instance is not configured (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND settings_database_flags ->> 'user options' IS NOT NULL;
    EOF
    }

    query "6.3.5" {
      description = "GCP CIS 6.3.5 Ensure 'remote access' database flag for Cloud SQL SQL Server instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND (settings_database_flags ->> 'remote access' != 'off'
            OR settings_database_flags ->> 'remote access' IS NULL);
    EOF
    }

    query "6.3.6" {
      description = "GCP CIS 6.3.6 Ensure '3625 (trace flag)' database flag for Cloud SQL SQL Server instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND (settings_database_flags ->> '3625' != 'off'
            OR settings_database_flags ->> '3625' IS NULL);
    EOF
    }

    query "6.3.7" {
      description = "GCP CIS 6.3.7 Ensure that the 'contained database authentication' database flag for Cloud SQL on the SQL Server instance is set to 'off' (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND (settings_database_flags ->> 'contained database authentication' != 'off'
            OR settings_database_flags ->> 'contained database authentication' IS NULL);
    EOF
    }

    query "6.4" {
      description = "GCP CIS 6.4 Ensure that the Cloud SQL database instance requires all incoming connections to use SSL (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND settings_ip_configuration_require_ssl = FALSE;
    EOF
    }

    query "6.5" {
      description = "GCP CIS 6.5 Ensure that Cloud SQL database instances are not open to the world (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name, gsisican.name
        FROM gcp_sql_instances gsi
        JOIN gcp_sql_instance_settings_ip_configuration_authorized_networks gsisican ON
        gsi.id = gsisican.instance_id
        WHERE database_version LIKE 'SQLSERVER%'
        AND gsisican.value = '0.0.0.0/0';
    EOF
    }

    query "6.6" {
      description = "GCP CIS 6.6 Ensure that Cloud SQL database instances do not have public IPs (Automated)"
      query = <<EOF
        SELECT gsi.project_id, gsi.name, gsiia."type"
        FROM gcp_sql_instances gsi
        JOIN gcp_sql_instance_ip_addresses gsiia ON
        gsi.id = gsiia.instance_id
        WHERE database_version LIKE 'SQLSERVER%'
        AND gsiia.type = 'PRIMARY';
    EOF
    }

    query "6.7" {
      description = "GCP CIS 6.7 Ensure that Cloud SQL database instances are configured with automated backups (Automated)"
      query = <<EOF
        SELECT project_id, name
        FROM gcp_sql_instances gsi
        WHERE database_version LIKE 'SQLSERVER%'
        AND settings_backup_enabled = FALSE;
    EOF
    }
  }

  policy "gcp-cis-section-7" {
    description = "GCP CIS Section 7"

    query "7.1" {
      description = "GCP CIS 7.1 Ensure that BigQuery datasets are not anonymously or publicly accessible (Automated)"
      query = <<EOF
        SELECT project_id, resource_id
        FROM gcp_bigquery_datasets
        JOIN gcp_bigquery_dataset_accesses ON
        gcp_bigquery_datasets.id = gcp_bigquery_dataset_accesses.dataset_id
        WHERE special_group IN('allAuthenticatedUsers', 'allUsers' )
    EOF
    }

    query "7.2" {
      description = "GCP CIS 7.2 Ensure that all BigQuery Tables are encrypted with Customer-managed encryption key (CMEK) (Automated)"
      query = <<EOF
        SELECT project_id, gcp_bigquery_datasets.resource_id
        FROM gcp_bigquery_datasets
        JOIN gcp_bigquery_dataset_tables ON
        gcp_bigquery_datasets.id = gcp_bigquery_dataset_tables.dataset_id
        WHERE encryption_configuration_kms_key_name = '';
    EOF
    }

    query "7.3" {
      description = "GCP CIS 7.3 Ensure that a Default Customer-managed encryption key (CMEK) is specified for all BigQuery Data Sets (Automated)"
      query = <<EOF
        SELECT project_id, resource_id
        FROM gcp_bigquery_datasets
        WHERE default_encryption_configuration_kms_key_name = '';
    EOF
    }
  }
}