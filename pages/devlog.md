---
layout: default
title: Dev log
permalink: /devlog/
---

<section class="page-hero">
  <div class="container narrow">
    <p class="eyebrow">Building log</p>
    <h1>Dev log</h1>
    <p class="lede">Ship notes, milestones, and decisions as we build userstories.io.</p>
    <p class="hint">Run <code>script/devlog.rb update</code> to pull in labeled PRs since the last run.</p>
  </div>
</section>

<section class="section">
  <div class="container narrow">
    {% if site.posts.size == 0 %}
      <p class="empty-state">No entries yet. Run <code>script/new_devlog_entry.rb</code> to add the first one.</p>
    {% else %}
      <ul class="entry-list entry-list-full">
        {% for post in site.posts %}
          <li class="entry-card">
            <div class="entry-meta">
              <time datetime="{{ post.date | date: '%Y-%m-%d' }}">{{ post.date | date: "%b %-d, %Y" }}</time>
              {% if post.type %}<span class="badge badge-{{ post.type }}">{{ post.type }}</span>{% endif %}
            </div>
            <h2><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h2>
            <p>{{ post.summary }}</p>
            <a class="text-link" href="{{ post.url | relative_url }}">Read entry &rarr;</a>
          </li>
        {% endfor %}
      </ul>
    {% endif %}
  </div>
</section>
