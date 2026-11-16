-- First entries for the Essays tab: Bea Ballard's writing on beaballard.com and
-- Alice Ballard-Rossiter's Substack. Each entry links to the piece where it is published;
-- no text is copied. Safe to re-run: entries already present are left alone.
insert into public.essays (slug, title, subtitle, kind, external_url, cover_url, source_author, source_name, source_words, source_date, status, published_at, author_id)
select v.slug, v.title, v.subtitle, v.kind, v.external_url, v.cover_url, v.source_author, v.source_name, v.source_words, v.source_date::timestamptz, 'published', v.source_date::timestamptz, null
from (values
  ('how-my-father-jg-ballard-foresaw-our-strange-present', 'How my father, JG Ballard, foresaw our strange present', 'On how his fiction anticipated reality television, social media, virtual reality and politics made for the screen.', 'link', 'https://www.beaballard.com/writing-bea-ballard/articles/how-jg-ballard-foresaw-our-present', null, 'Bea Ballard', 'The Guardian', null, '2016-11-20T12:00:00Z'),
  ('the-greatest-tv-show-on-earth', 'The greatest TV show on earth', 'An essay on what her father saw in television, and how media and technology came to shape our sense of what is real.', 'link', 'https://www.beaballard.com/writing-bea-ballard/the-greatest-tv-show-on-earth', null, 'Bea Ballard', 'Deep Ends: The J.G. Ballard Anthology', null, '2016-09-23T12:00:00Z'),
  ('obituary-jg-ballard', 'Obituary: JG Ballard', 'A daughter remembers the novelist as a devoted single parent and grandfather.', 'link', 'https://www.beaballard.com/writing-bea-ballard/jg-ballard-obituary', null, 'Bea Ballard', 'The Guardian', null, '2009-12-13T12:00:00Z'),
  ('my-dad-the-perfect-mum', 'My dad, the perfect mum', 'How J.G. Ballard brought up three children alone after their mother’s sudden death.', 'link', 'https://www.beaballard.com/writing-bea-ballard/jg-ballard', null, 'Bea Ballard', 'The Times', null, '2009-04-26T12:00:00Z'),
  ('the-death-of-taste', 'The Death of Taste', 'Slop was never about the machine.', 'substack', 'https://youshouldknowabout.substack.com/p/the-death-of-taste', 'https://substackcdn.com/image/fetch/$s_!aG-w!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F9c2c1ec2-f228-4d3f-8710-71d1be8d0c9b_1520x700.png', 'Alice BR', null, 1281, '2026-11-13T16:26:09.187Z'),
  ('experiments-in-virality-and-the-positive', 'The Positive Side of The Transactionality Epidemic & Experiments in Virality', 'What I learned from my own online performance, and what you can use too in your own life.', 'substack', 'https://youshouldknowabout.substack.com/p/experiments-in-virality-and-the-positive', 'https://substackcdn.com/image/fetch/$s_!29X7!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fefb2fbf2-b221-47f5-abc7-13661698faed_1114x1442.png', 'Alice BR', null, 1484, '2026-11-09T22:51:43.787Z'),
  ('the-great-consolidation', 'The Great Consolidation', '', 'substack', 'https://youshouldknowabout.substack.com/p/the-great-consolidation', 'https://substackcdn.com/image/fetch/$s_!AJws!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fef519f19-9ae4-4c3f-b76b-62504b1d05d5_1650x990.png', 'Alice BR', null, 3583, '2026-11-03T15:46:57.891Z'),
  ('the-transactionality-epidemic-part', 'The Transactionality Epidemic, Part II: The Receipts', 'The bottom of the ladder got eaten, the top got funded, and the newcomers are paying for both.', 'substack', 'https://youshouldknowabout.substack.com/p/the-transactionality-epidemic-part', 'https://substackcdn.com/image/fetch/$s_!_pQi!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fb1a600b0-ade1-425a-ab6a-48aae6cebbfd_1600x1184.png', 'Alice BR', null, 3266, '2026-11-01T19:28:25.016Z'),
  ('the-transactionality-epidemic-and', 'The Transactionality Epidemic & Era of Generalists', 'How market forces broke Silicon Valley’s relationship culture—and created an unexpected competitive advantage for generalists and genuinely good people.', 'substack', 'https://youshouldknowabout.substack.com/p/the-transactionality-epidemic-and', 'https://substackcdn.com/image/fetch/$s_!67x_!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F69c0faf9-47bd-49c4-bd3b-54ce2c7c8785_2051x1165.png', 'Alice BR', null, 3763, '2026-01-29T22:03:25.485Z'),
  ('tessl-startups-you-should-know-about', 'Tessl: Startups You Should Know About', 'AI-Native Software Development', 'substack', 'https://youshouldknowabout.substack.com/p/tessl-startups-you-should-know-about', 'https://substack-post-media.s3.amazonaws.com/public/images/23c7b307-d566-4904-a19e-7471294e5d5a_1125x720.png', 'Alice BR', null, 464, '2024-10-02T17:45:58.511Z')
) as v(slug, title, subtitle, kind, external_url, cover_url, source_author, source_name, source_words, source_date)
where not exists (select 1 from public.essays e where e.slug = v.slug or e.external_url = v.external_url);

-- Themes for the Essays tab, each tied to part of J.G. Ballard's work, and the first arrangement:
-- within a theme the two authors alternate where both have written on the subject.
insert into public.themes (name, blurb, position) values
  ('Screens, feeds and the performed self', 'What television began and the feed finished. The ground of The Atrocity Exhibition and of his writing on television.', 10),
  ('Silicon Valley from the inside', 'Closed worlds of work and money, and what they do to the people inside them. The territory of Super-Cannes and Cocaine Nights.', 20),
  ('The man himself', 'Shepperton, fatherhood and family. The life behind Miracles of Life and The Kindness of Women.', 30)
on conflict (name) do nothing;

update public.essays e set theme = v.theme, sort_order = v.ord
from (values
  ('the-death-of-taste',                                   'Screens, feeds and the performed self', 1),
  ('how-my-father-jg-ballard-foresaw-our-strange-present', 'Screens, feeds and the performed self', 2),
  ('experiments-in-virality-and-the-positive',             'Screens, feeds and the performed self', 3),
  ('the-greatest-tv-show-on-earth',                        'Screens, feeds and the performed self', 4),
  ('the-transactionality-epidemic-and',                    'Silicon Valley from the inside', 1),
  ('the-transactionality-epidemic-part',                   'Silicon Valley from the inside', 2),
  ('the-great-consolidation',                              'Silicon Valley from the inside', 3),
  ('tessl-startups-you-should-know-about',                 'Silicon Valley from the inside', 4),
  ('my-dad-the-perfect-mum',                               'The man himself', 1),
  ('obituary-jg-ballard',                                  'The man himself', 2)
) as v(slug, theme, ord)
where e.slug = v.slug and e.theme is null;   -- leaves any later rearrangement alone

select t.position, e.theme, e.sort_order, e.source_author, e.title from public.essays e left join public.themes t on t.name = e.theme order by t.position, e.sort_order;

-- Quote & prompt of the week: the first two posts. Quotations supplied by the estate.
-- Safe to re-run: a post with the same headline is left alone.
insert into public.threads (kind, title, quote, quote_source, body, author_id, created_at)
select 'weekly', v.title, v.quote, v.quote_source, v.body, null, v.created_at::timestamptz
from (values
  ('Governed by reason?',
   $q$The advanced societies of the future will not be governed by reason. They will be driven by irrationality, by competing systems of psychopathology$q$,
   'letter, 2003',
   $q$Where did you see this last week? Name one thing in the news that ran on something other than reason.$q$,
   '2026-11-09T17:00:00Z'),
  ('Is the future boring?',
   $q$I would sum up my fear about the future in one word: boring. And that's my one fear: that everything has happened; nothing exciting or new or interesting is ever going to happen again ... the future is just going to be a vast, conforming suburb of the soul$q$,
   'interview',
   $q$Was he right? Tell us the last thing that felt new to you.$q$,
   '2026-11-16T17:00:00Z')
) as v(title, quote, quote_source, body, created_at)
where not exists (select 1 from public.threads t where t.kind = 'weekly' and t.title = v.title);

select created_at::date, title, quote_source, left(quote, 50) as quote_start, body from public.threads where kind = 'weekly' order by created_at desc;
