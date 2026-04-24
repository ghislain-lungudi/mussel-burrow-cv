# How to publish this repository

This file walks you through the actual publication steps. Once you finish
them, your repository will be:

1. Public on GitHub,
2. Archived on Zenodo with a permanent DOI,
3. Linked from the paper via the Data Availability Statement.

## Step 0 — Create your GitHub and Zenodo accounts (first time only)

If you have never published code on GitHub before, do this first. Expect
about 5 minutes total.

### Create a GitHub account

1. Go to https://github.com/signup.
2. Enter your email, a password, and pick a username. **Choose your
   username carefully** — it will appear in the URL of every repo you
   publish, and it will be cited in the paper. A username derived from
   your real name (e.g. `ghislain-lungudi`) is the academic norm,
   because it makes your publications findable and links them to your
   professional identity. You cannot easily change it later without
   breaking links.
3. Verify your email.
4. You do not need to create a repository from the GitHub interface —
   the `gh` CLI or the `git push` commands below will do it for you.
5. (Recommended) In **Settings → Emails**, tick "Keep my email
   addresses private" so your commit history does not publish your
   personal email. GitHub will give you a `@users.noreply.github.com`
   alias to use instead. Set it with:

   ```bash
   git config --global user.email "your-github-id+username@users.noreply.github.com"
   git config --global user.name  "Your Name"
   ```

   The exact noreply email address is shown on the Emails settings
   page. This step is optional but recommended for academic publication.

6. (Recommended) Link your ORCID to your GitHub profile. Go to
   **Settings → Public profile** and paste your ORCID URL in the
   "Social accounts" section:

   ```
   https://orcid.org/0000-0002-1121-6275
   ```

### Create a Zenodo account

1. Go to https://zenodo.org/signup.
2. The easiest path is **"Sign up with ORCID"** — click the ORCID
   button, log in with your ORCID credentials, and authorize Zenodo.
   Your ORCID (0000-0002-1121-6275) will be linked to the account
   automatically, so your Zenodo releases will show up on your ORCID
   record.
3. Confirm your email when Zenodo asks.

### Install the tools you need locally

- **Git** — https://git-scm.com/downloads (usually pre-installed on
  Linux/macOS).
- **GitHub CLI** (optional but makes Step 3 a one-liner) —
  https://cli.github.com/. After install, run `gh auth login` once.

## Prerequisites (summary)

- A **GitHub account** (see Step 0). https://github.com/signup
- A **Zenodo account** (see Step 0). https://zenodo.org/signup
- **Git** installed locally. https://git-scm.com/downloads

Optional but recommended: the **GitHub CLI** (`gh`) for one-command repo
creation. https://cli.github.com/

## Step 1 — Personalize the placeholders

Before pushing, replace the placeholders in these files:

1. `README.md` — replace `ghislain-lungudi` with your actual GitHub
   username in the clone URL and the badge URL.
2. `CITATION.cff` — same.
3. `docs/data_availability.md` — same.
4. `CITATION.cff` — add your ORCID and your co-authors' ORCIDs if you
   have them. Remove the `# orcid:` comment markers once you fill them
   in.
5. `.zenodo.json` — no change needed yet; the DOI placeholder will be
   filled in automatically by Zenodo at first release.

A quick sed command that does steps 1–3 at once (replace `your-username`):

```bash
grep -rl 'ghislain-lungudi' . | xargs sed -i 's|ghislainlungudi|your-username|g'
```

## Step 2 — Initialize git and make the first commit

From the repository root:

```bash
git init
git add .
git commit -m "Initial public release (v1.0.0)"
git branch -M main
```

## Step 3 — Create the GitHub repo and push

### Option A: with the GitHub CLI (one command)

```bash
gh repo create mussel-burrow-cv --public --source=. --remote=origin --push
```

Done. The repo is now public at
`https://github.com/ghislain-lungudi/mussel-burrow-cv`.

### Option B: without the CLI

1. Go to https://github.com/new.
2. Name the repo `mussel-burrow-cv`. Set visibility to **Public**. Do
   **not** initialize with a README, .gitignore, or license — you
   already have them.
3. Click **Create repository**.
4. Back in your terminal:

   ```bash
   git remote add origin https://github.com/ghislain-lungudi/mussel-burrow-cv.git
   git push -u origin main
   ```

## Step 4 — Connect to Zenodo

1. Log in to https://zenodo.org.
2. Go to **Settings → GitHub**
   (https://zenodo.org/account/settings/github/).
3. Authorize Zenodo to access your GitHub account.
4. In the list of your repositories, flip the toggle next to
   `mussel-burrow-cv` to **On**.

Zenodo is now watching the repo. Any GitHub release you cut from now on
will be auto-archived and given a DOI.

## Step 5 — Cut the v1.0.0 release

### Option A: with the GitHub CLI

```bash
git tag -a v1.0.0 -m "Version 1.0.0 — accompanies submission to Ecological Informatics"
git push origin v1.0.0
gh release create v1.0.0 --title "v1.0.0" --notes-file CHANGELOG.md
```

### Option B: on github.com

1. Go to `https://github.com/ghislain-lungudi/mussel-burrow-cv/releases/new`.
2. Tag: `v1.0.0`. Title: `v1.0.0`.
3. Paste the contents of `CHANGELOG.md` into the description.
4. Click **Publish release**.

Within a minute or two, Zenodo will email you a confirmation with a DOI.
It looks like `10.5281/zenodo.1234567`.

## Step 6 — Put the real DOI back into the repo

Replace the `10.5281/zenodo.XXXXXXX` placeholder in these files:

- `README.md` (Zenodo badge + citation block)
- `CITATION.cff` (`doi:` field)
- `docs/data_availability.md`

Then commit and push:

```bash
git add README.md CITATION.cff docs/data_availability.md
git commit -m "Add Zenodo DOI for v1.0.0"
git push
```

You do **not** need to cut a new release for this. The v1.0.0 tag still
points at the archived snapshot Zenodo already minted; the DOI is stable.

Tip: Zenodo also mints a **concept DOI** that always resolves to the
newest release. It is the DOI you should cite in the paper if you expect
to cut bug-fix releases before acceptance. Both DOIs are visible on your
Zenodo record page.

## Step 7 — Add the DOI to the paper

In the Data Availability Statement of the manuscript, replace the
placeholder DOI with the real Zenodo concept DOI. Re-export the PDF and
re-upload to the journal's submission system. If the journal generated a
pre-acceptance tracking DOI for the manuscript itself, keep them
separate — the Zenodo DOI is for the code release, not the paper.

## Step 8 — (Optional but recommended) Double-blind review

If the journal uses double-blind review, keep the repo **private** until
acceptance, and provide reviewers with an anonymized view:

- https://anonymous.4open.science  — mirror the repo and share the
  generated anonymous URL in your cover letter.
- At acceptance, flip the GitHub repo to public and proceed with Steps 4
  and onward.

Zenodo also supports a private-with-share-link mode for pre-acceptance
review.

---

## Summary — the shortest path

If you just want the fastest possible sequence of commands, assuming
`gh` is installed and you are logged in:

```bash
cd mussel-burrow-cv
# edit placeholders first:
sed -i 's|ghislainlungudi|your-actual-username|g' README.md CITATION.cff docs/data_availability.md

git init
git add .
git commit -m "Initial public release (v1.0.0)"
git branch -M main

gh repo create mussel-burrow-cv --public --source=. --remote=origin --push

# go to https://zenodo.org/account/settings/github/ and toggle on mussel-burrow-cv

git tag -a v1.0.0 -m "v1.0.0 — accompanies submission to Ecological Informatics"
git push origin v1.0.0
gh release create v1.0.0 --title "v1.0.0" --notes-file CHANGELOG.md

# wait ~1 minute for the Zenodo DOI email, then:
sed -i 's|10.5281/zenodo.XXXXXXX|10.5281/zenodo.REAL_DOI|g' README.md CITATION.cff docs/data_availability.md
git add -A
git commit -m "Add Zenodo DOI for v1.0.0"
git push
```

Total time: under 10 minutes, not counting the Zenodo-GitHub auth step.
