---
layout: default
title: Home
permalink: /
---

<section class="hero">
  <div class="container hero-grid">
    <div class="hero-copy">
      <p class="eyebrow">For developers on GitHub</p>
      <h1>Stakeholder feedback, structured and in GitHub.</h1>
      <p class="lede">
        Share a link. Collaborators submit stories in plain language. You triage them,
        and a GitHub issue is created when you accept.
      </p>
      <div class="hero-actions">
        <a class="btn btn-primary" href="https://github.com/{{ site.github_username }}/{{ site.repository }}">View on GitHub</a>
        <a class="btn btn-ghost" href="{{ '/features/' | relative_url }}">See features</a>
      </div>
    </div>
    <div class="hero-card">
      <p class="card-label">Triage inbox</p>
      <ul class="inbox-preview">
        <li class="inbox-item inbox-item-active">
          <div>
            <strong>Add dark mode to the dashboard</strong>
            <span>Maya R. · Horizon App</span>
          </div>
          <span class="status status-pending">pending</span>
        </li>
        <li class="inbox-item">
          <div>
            <strong>Export submissions as CSV</strong>
            <span>Tom B. · Horizon App</span>
          </div>
          <span class="status status-pending">pending</span>
        </li>
        <li class="inbox-item">
          <div>
            <strong>Show estimated delivery date</strong>
            <span>Priya K. · Storefront</span>
          </div>
          <span class="status status-accepted">accepted</span>
        </li>
      </ul>
      <p class="card-foot">2 pending · 1 accepted this week</p>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="section-head">
      <h2>How it works</h2>
      <p>Three steps from repo to structured feedback in your workflow.</p>
    </div>
    <ol class="steps">
      <li>
        <span class="step-num">01</span>
        <h3>Connect your repo</h3>
        <p>Sign in with GitHub and link a project to any repository you own.</p>
      </li>
      <li>
        <span class="step-num">02</span>
        <h3>Share a link</h3>
        <p>Send your portal link to stakeholders. They sign in with email — no GitHub account needed.</p>
      </li>
      <li>
        <span class="step-num">03</span>
        <h3>Accept to ship</h3>
        <p>Review submissions in your inbox. Accept what's actionable and a GitHub issue is created instantly.</p>
      </li>
    </ol>
  </div>
</section>

<section class="section section-muted">
  <div class="container">
    <div class="section-head">
      <h2>Latest from the dev log</h2>
      <p>Ship notes, milestones, and what we're building next.</p>
    </div>
    <ul class="entry-list">
      {% assign recent = site.posts | slice: 0, 3 %}
      {% for post in recent %}
        <li class="entry-card">
          <div class="entry-meta">
            <time datetime="{{ post.date | date: '%Y-%m-%d' }}">{{ post.date | date: "%b %-d, %Y" }}</time>
            {% if post.type %}<span class="badge badge-{{ post.type }}">{{ post.type }}</span>{% endif %}
          </div>
          <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
          <p>{{ post.summary }}</p>
        </li>
      {% endfor %}
    </ul>
    <p class="section-cta"><a class="text-link" href="{{ '/devlog/' | relative_url }}">Read the full dev log &rarr;</a></p>
  </div>
</section>

<section class="section">
  <div class="container cta-panel">
    <h2>Building in the open</h2>
    <p>This site tracks product progress. The app itself lives in the main repository.</p>
    <a class="btn btn-primary" href="{{ '/roadmap/' | relative_url }}">View roadmap</a>
  </div>
</section>
