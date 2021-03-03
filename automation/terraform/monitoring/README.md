<p><img src="https://storage.googleapis.com/coda-charts/Mina_Icon_Secondary_RGB_Black.png" alt="Mina logo" title="mina" align="left" height="60" /></p>

# Testnet Monitoring & Alerting :fire_engine: Guide

**Table of Contents**
- [Updating Testnet Alerts](#update-testnet-alerts)
    - [Developing alert expressions](#developling)
    - [Testing](#testing)
    - [Deployment](#deployment)
- [Alert Status](#alert-status)
    - [GrafanaCloud Config](#grafancloud-config)
    - [Alertmanager UI](#alertmanager-ui)
    - [PagerDuty](#pagerduty)
- [HowTo](#howto)
    - [Silence Alerts](#silence-alerts)
    - [Update Alert Receivers](#alert-receivers)
    - [View Alert Metrics](#alert-metrics)

## Updating Testnet Alerts

#### Developing alert expressions

Developing alert expressions consists of using Prometheus's domain-specific [query language](https://prometheus.io/docs/prometheus/latest/querying/basics/) ([examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)) coupled with its alert rules specification [format](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) for devising metric and alerting conditions/rules.

To enable variability when defining these rules, each rule set or group is implemented using *terraform*'s [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) and `(${ ... })` templating mechanisms for including variable substition where appropriate. A standard set of such testnet alert rules based on templates is defined [here](https://github.com/MinaProtocol/mina/blob/develop/automation/terraform/modules/testnet-alerts/templates/testnet-alert-rules.yml.tpl#L6) and should be edited when adding rules to be applied to all testnets.

Generally, when adding or updating alerts:
1. consult Grafanacloud Prometheus Explorer to ensure metric to alert on is collected by infrastructure's Prometheus instances
1. apply alerting changes to *testnet-alert-rules.yml.tpl*

#### Testing

Testing of testnet alerts currently involves 2 operations, `linting` and `checking` of alerting rules defined within *testnet-alert-rules.yml.tpl*, both of which can executed automatically in CI or manually within a developer's local environment.

##### Linting

* *automation:* executed by CI's *Lint/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Lint/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file
* *manual:*

    `terraform apply -target module.o1testnet_alerts.docker_container.lint_rules_config` from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory

##### Check alerts against best practices

* *automation:* executed by CI's *Lint/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Lint/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file
* *manual:*
    `terraform apply -target module.o1testnet_alerts.docker_container.check_rules_config` from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory

#### Deployment

* *automation:* executed by CI's *Release/TestnetAlerts* [job](https://github.com/MinaProtocol/mina/blob/develop/buildkite/src/Jobs/Lint/TestnetAlerts.dhall) when a change is detected to the testnet-alerts template file and linting/checking of alerts has succeeded
* *manual:*
    `terraform apply -target module.o1testnet_alerts.docker_container.sync_alert_rules` from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory.

**Note:** operation will sync provisioned alerts with exact match of alert file state (e.g. alerts removed from the alert file will be unprovisioned on Grafanacloud)

## Alert Status

#### GrafanCloud Config

To view the current testnet alerting rules config or verify that changes were applied correctly following a deployment, visit O(1) Lab's Grafanacloud rules config [site](https://o1testnet.grafana.net/a/grafana-alerting-ui-app/?tab=rules&rulessource=grafanacloud-o1testnet-prom).

**Note:** ensure the rules datasource is set to `grafanacloud-o1testnet-prom`. 

#### Alertmanager UI

Alerting rule violations can also be viewed in Grafanacloud's Alertmanager [UI](https://alertmanager-us-central1.grafana.net/alertmanager/#/alerts). This site provides an overview of all violating rule conditions in addition to rules that have been silenced. 

#### PagerDuty

...

## HowTo

#### Silence Alerts

* Pagerduty alert suppression: see [guide](https://support.pagerduty.com/docs/event-management#suppressing-alerts)
* Alertmanager alert silencing: new [silence creation](https://alertmanager-us-central1.grafana.net/alertmanager/#/silences/new)

##### Creating new silences

When creating new alert silences (from the above link or otherwise), you'll likely want to make use of the AlertManager's `Matchers` construct, which basically consists of a set of key-value pairs used to target the alert to silence. For example, if silencing the "LowFillRate" alert currently firing for testnet *devnet*, you would create a new silence with individual `Matchers` for the alert name and testnet like the following:

| Name | Value|
| ------------- | ------------- |
| testnet  | devnet  | 
| alertname  | LowFillRate  |

Note the `Start`, `Duration` and `End` inputs. Commonly only the duration of a silence would be updated though Alertmanager supports specification of start and end times based on internet timing standards [RFC3339](https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14).

* Be sure to set the *Creator* and *Comments* field accordingly to provide insight into the reasoning for the silence and guidelines for following up.

#### Update Alert Receivers

Alert receivers are communication/reporting endpoints for messaging alert rules/conditions which are in violation. Think a *PagerDuty* page, *incident* email or SMS message or Discord notification. A list of available receivers along with their associated configuration documentation can be found [here](https://prometheus.io/docs/alerting/latest/configuration/).

* *manual:*
    `terraform apply -target module.o1testnet_alerts.docker_container.update_alert_receivers` from the [automation monitoring](https://github.com/MinaProtocol/mina/tree/develop/automation/terraform/monitoring) directory.

#### View Alert Metrics

...