"""Generate the CVAsCode architecture header.

Run this script from the project root:

    uv run python diagram.py
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.analytics import Athena, Glue
from diagrams.aws.management import Cloudwatch
from diagrams.aws.network import CloudFront
from diagrams.aws.security import IAM
from diagrams.aws.storage import S3
from diagrams.generic.device import Mobile
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.iac import Terraform
from diagrams.onprem.vcs import Github
from diagrams.saas.chat import Telegram


GRAPH_ATTRIBUTES = {
    "bgcolor": "#ffffff",
    "fontcolor": "#0f172a",
    "fontname": "Arial Bold",
    "fontsize": "24",
    "labelloc": "t",
    "pad": "0.45",
    "nodesep": "0.55",
    "ranksep": "0.8",
    "splines": "spline",
    "outputorder": "edgesfirst",
}

NODE_ATTRIBUTES = {
    "fontcolor": "#1e293b",
    "fontname": "Arial",
    "fontsize": "11",
    "labelloc": "b",
    "imagescale": "true",
}

EDGE_ATTRIBUTES = {
    "color": "#64748b",
    "fontcolor": "#334155",
    "fontname": "Arial",
    "fontsize": "9",
    "penwidth": "1.8",
    "arrowsize": "0.7",
}

CLUSTER_ATTRIBUTES = {
    "bgcolor": "#f8fafc",
    "color": "#cbd5e1",
    "fontcolor": "#0f172a",
    "fontname": "Arial Bold",
    "fontsize": "14",
    "margin": "18",
    "penwidth": "1.4",
    "style": "rounded,filled",
}


def flow(label: str, color: str) -> Edge:
    """Create a readable colored connection."""
    return Edge(label=label, color=color, fontcolor="#334155")


with Diagram(
    "CVAsCode | Secure AWS Resume Platform",
    filename="assets/header",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=GRAPH_ATTRIBUTES,
    node_attr=NODE_ATTRIBUTES,
    edge_attr=EDGE_ATTRIBUTES,
):
    visitors = Mobile("Visitors")

    with Cluster("Global website delivery", graph_attr=CLUSTER_ATTRIBUTES):
        cdn = CloudFront("CloudFront\nHTTPS and CDN")
        website = S3("Private S3 bucket\nHTML, CSS, JavaScript")

        cdn >> flow("Origin Access Control", "#38bdf8") >> website

    visitors >> flow("HTTPS", "#38bdf8") >> cdn

    with Cluster("Access-log analytics", graph_attr=CLUSTER_ATTRIBUTES):
        delivery = Cloudwatch("CloudWatch API\nLog delivery")
        access_logs = S3("S3 access logs\nJSON, 90-day retention")
        catalog = Glue("Glue Data Catalog\nProjected partitions")
        queries = Athena("Athena\nNamed queries")
        query_results = S3("S3 query results\n7-day retention")

        delivery >> flow("JSON logs", "#a78bfa") >> access_logs
        access_logs >> Edge(color="#a78bfa") >> catalog
        catalog >> flow("Schema", "#a78bfa") >> queries
        queries >> flow("Results", "#a78bfa") >> query_results

    cdn >> flow("Access events", "#a78bfa") >> delivery

    with Cluster("Infrastructure delivery", graph_attr=CLUSTER_ATTRIBUTES):
        repository = Github("GitHub repository")
        actions = GithubActions("GitHub Actions\nTest, deploy, drift checks")
        terraform = Terraform("Terraform\nInfrastructure as code")
        identity = IAM("AWS IAM\nOIDC role")
        state = S3("S3 backend\nState and plan artifacts")
        notifications = Telegram("Telegram\nRun notifications")

        repository >> flow("Push or schedule", "#34d399") >> actions
        actions >> flow("OIDC", "#fbbf24") >> identity
        identity >> flow("Short-lived credentials", "#fbbf24") >> terraform
        terraform >> flow("Remote state", "#34d399") >> state
        actions >> flow("Status", "#f472b6") >> notifications

    terraform >> flow("Manage AWS", "#34d399") >> cdn
