# WIF Explained Simply

## What is WIF (Workload Identity Federation)?

Normally, to let GitHub Actions talk to GCP, you'd create a JSON key file and store it as a secret. That key never expires and is a security risk if leaked.

**WIF removes the need for any key file.**

Instead, GitHub proves "I am a GitHub Actions run from repo X" using a short-lived token (OIDC token). GCP checks that proof and hands back temporary access — no keys stored anywhere.

```
GitHub Actions run
   → "Here's my OIDC token proving who I am"
      → GCP verifies it
         → GCP gives temporary credentials (valid for minutes)
            → Pipeline deploys to GKE
```

---

## Workload Identity Pool

Think of it as a **guest list manager** in GCP.

- It is a container that holds trusted external identity sources (like GitHub).
- You create one pool and then add "providers" to it.
- In this setup: pool name is `github-pool2`.

> Analogy: A nightclub has a guest list. The pool is the guest list book.

---

## Provider

A **provider** is the specific external system you trust inside the pool.

- In this case, the provider is GitHub Actions (via OIDC).
- Issuer URL `https://token.actions.githubusercontent.com` tells GCP: "tokens from this URL are from GitHub."
- GCP uses this to verify the incoming OIDC token is genuinely from GitHub.

> Analogy: The provider is the rule "only accept guests from Company X's HR list."

---

## Attribute Mapping — What Does It Mean?

When GitHub sends its OIDC token, it contains claims (facts about the run). The mapping translates GitHub's language into GCP's language.

| Mapping | Means |
|---|---|
| `google.subject` → `assertion.sub` | GCP's identity field = GitHub's unique subject (e.g. `repo:Venkateshd279/gke-cluster-guide:ref:refs/heads/main`) |
| `attribute.repository` → `assertion.repository` | A custom field GCP can read = the GitHub repo name |

### Attribute Condition

```
attribute.repository == "Venkateshd279/gke-cluster-guide"
```

This is a **filter/guard**. It says: only allow tokens that came from this specific repo. Even if someone else has a GitHub OIDC token, they can't use your GCP resources.

> Analogy: Mapping is translating the guest's passport. The condition is checking it says the right company.

---

## Service Account

A **Service Account** is a GCP identity that has permissions to do things (deploy to GKE, push images, etc.).

- Humans log in with their Google account.
- Automated systems (like GitHub Actions) use a Service Account.
- In this setup: `github-actions-sa@thematic-ruler-494815-f6.iam.gserviceaccount.com`
- It has roles: `Kubernetes Engine Developer` + `Artifact Registry Writer`

> Analogy: The service account is a robot employee badge that has access to specific doors.

---

## Why Grant Access (Step 4)?

WIF by itself just verifies GitHub's identity. But to actually **do things in GCP**, the pipeline needs to **impersonate** the service account.

The grant in Step 4 says:

> "GitHub Actions runs from repo `Venkateshd279/gke-cluster-guide` are allowed to act as `github-actions-sa`."

Without this, GCP would verify GitHub's identity but then say "so what? you're not allowed to use this service account."

Two permissions are granted:
- **Workload Identity User** — allows the WIF principal to impersonate the service account.
- **Service Account Token Creator** — allows the pipeline to generate short-lived tokens on behalf of the service account (needed for the `google-github-actions/auth` action to work).

---

## Full Flow Summary

```
1. GitHub Actions run starts
2. GitHub issues an OIDC token: "I am repo Venkateshd279/gke-cluster-guide"
3. GCP checks: is this token from the trusted provider? Yes.
4. GCP checks attribute condition: is this the allowed repo? Yes.
5. GCP checks: is this principal allowed to use github-actions-sa? Yes (Step 4 grant).
6. GCP issues temporary credentials for github-actions-sa.
7. Pipeline uses those credentials to deploy to GKE.
```

No keys. No secrets rotation. Expires automatically after the run.
