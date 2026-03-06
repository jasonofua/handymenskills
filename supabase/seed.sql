-- Seed data for Artisan Marketplace

-- ===========================================
-- SUBSCRIPTION PLANS
-- ===========================================
INSERT INTO subscription_plans (name, slug, duration_months, price, features, max_active_applications, priority_listing, sort_order) VALUES
  ('1 Month', '1-month', 1, 500.00, '["Apply to jobs", "Basic profile visibility", "Up to 10 active applications"]', 10, false, 1),
  ('2 Months', '2-months', 2, 900.00, '["Apply to jobs", "Basic profile visibility", "Up to 10 active applications", "Save 10%"]', 10, false, 2),
  ('6 Months', '6-months', 6, 2400.00, '["Apply to jobs", "Enhanced profile visibility", "Up to 15 active applications", "Save 20%"]', 15, false, 3),
  ('1 Year', '1-year', 12, 4500.00, '["Apply to jobs", "Priority listing", "Up to 20 active applications", "Save 25%", "Verified badge"]', 20, true, 4),
  ('2 Years', '2-years', 24, 8000.00, '["Apply to jobs", "Priority listing", "Up to 25 active applications", "Save 33%", "Verified badge"]', 25, true, 5),
  ('3 Years', '3-years', 36, 11000.00, '["Apply to jobs", "Priority listing", "Unlimited active applications", "Save 39%", "Verified badge"]', 50, true, 6),
  ('5 Years', '5-years', 60, 17000.00, '["Apply to jobs", "Priority listing", "Unlimited active applications", "Save 43%", "Verified badge", "Featured worker"]', 100, true, 7);

-- ===========================================
-- CATEGORIES & SKILLS
-- ===========================================

-- Plumbing
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Plumbing', 'plumbing', 'plumbing', 'Water systems, pipes, and drainage services', 1);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Pipe Installation', 'pipe-installation'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Pipe Repair', 'pipe-repair'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Drain Cleaning', 'drain-cleaning'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Water Heater Installation', 'water-heater-installation'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Toilet Repair', 'toilet-repair'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Borehole Drilling', 'borehole-drilling'),
  ((SELECT id FROM categories WHERE slug = 'plumbing'), 'Water Tank Installation', 'water-tank-installation');

-- Electrical
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Electrical', 'electrical', 'electrical', 'Electrical wiring, installation, and repair services', 2);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'House Wiring', 'house-wiring'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'Generator Repair', 'generator-repair'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'Solar Installation', 'solar-installation'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'Inverter Installation', 'inverter-installation'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'Electrical Fault Finding', 'electrical-fault-finding'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'CCTV Installation', 'cctv-installation'),
  ((SELECT id FROM categories WHERE slug = 'electrical'), 'Appliance Repair', 'appliance-repair');

-- Carpentry
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Carpentry', 'carpentry', 'carpentry', 'Woodwork, furniture making, and repair', 3);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Furniture Making', 'furniture-making'),
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Door Installation', 'door-installation'),
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Roof Repair', 'roof-repair'),
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Cabinet Making', 'cabinet-making'),
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Wood Flooring', 'wood-flooring'),
  ((SELECT id FROM categories WHERE slug = 'carpentry'), 'Window Frame Installation', 'window-frame-installation');

-- Painting
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Painting', 'painting', 'painting', 'Interior and exterior painting services', 4);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'painting'), 'Interior Painting', 'interior-painting'),
  ((SELECT id FROM categories WHERE slug = 'painting'), 'Exterior Painting', 'exterior-painting'),
  ((SELECT id FROM categories WHERE slug = 'painting'), 'POP Ceiling', 'pop-ceiling'),
  ((SELECT id FROM categories WHERE slug = 'painting'), 'Screeding', 'screeding'),
  ((SELECT id FROM categories WHERE slug = 'painting'), 'Wall Art/Mural', 'wall-art-mural'),
  ((SELECT id FROM categories WHERE slug = 'painting'), 'Wallpaper Installation', 'wallpaper-installation');

-- Cleaning
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Cleaning', 'cleaning', 'cleaning', 'Home, office, and industrial cleaning', 5);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'House Cleaning', 'house-cleaning'),
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'Office Cleaning', 'office-cleaning'),
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'Deep Cleaning', 'deep-cleaning'),
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'Carpet Cleaning', 'carpet-cleaning'),
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'Fumigation', 'fumigation'),
  ((SELECT id FROM categories WHERE slug = 'cleaning'), 'Post-Construction Cleaning', 'post-construction-cleaning');

-- Tailoring
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Tailoring', 'tailoring', 'tailoring', 'Clothing design, sewing, and alterations', 6);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'tailoring'), 'Men''s Clothing', 'mens-clothing'),
  ((SELECT id FROM categories WHERE slug = 'tailoring'), 'Women''s Clothing', 'womens-clothing'),
  ((SELECT id FROM categories WHERE slug = 'tailoring'), 'Aso Oke Weaving', 'aso-oke-weaving'),
  ((SELECT id FROM categories WHERE slug = 'tailoring'), 'Alterations', 'alterations'),
  ((SELECT id FROM categories WHERE slug = 'tailoring'), 'Embroidery', 'embroidery');

-- Catering
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Catering', 'catering', 'catering', 'Food preparation and event catering', 7);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'catering'), 'Event Catering', 'event-catering'),
  ((SELECT id FROM categories WHERE slug = 'catering'), 'Private Chef', 'private-chef'),
  ((SELECT id FROM categories WHERE slug = 'catering'), 'Cake Making', 'cake-making'),
  ((SELECT id FROM categories WHERE slug = 'catering'), 'Small Chops', 'small-chops'),
  ((SELECT id FROM categories WHERE slug = 'catering'), 'Local Cuisine', 'local-cuisine');

-- Beauty & Styling
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Beauty & Styling', 'beauty-styling', 'beauty', 'Hair, makeup, and personal grooming', 8);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Hair Styling', 'hair-styling'),
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Barbing', 'barbing'),
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Makeup', 'makeup'),
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Manicure & Pedicure', 'manicure-pedicure'),
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Braiding', 'braiding'),
  ((SELECT id FROM categories WHERE slug = 'beauty-styling'), 'Lash Extensions', 'lash-extensions');

-- Technology & IT
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Technology & IT', 'technology-it', 'technology', 'Computer repair, networking, and IT services', 9);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'Computer Repair', 'computer-repair'),
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'Phone Repair', 'phone-repair'),
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'Networking', 'networking'),
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'CCTV Setup', 'cctv-setup'),
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'Web Development', 'web-development'),
  ((SELECT id FROM categories WHERE slug = 'technology-it'), 'Graphic Design', 'graphic-design');

-- Mechanical
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Mechanical', 'mechanical', 'mechanical', 'Vehicle and machinery repair', 10);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Car Repair', 'car-repair'),
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Car Electrician', 'car-electrician'),
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Panel Beating', 'panel-beating'),
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Car AC Repair', 'car-ac-repair'),
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Motorcycle Repair', 'motorcycle-repair'),
  ((SELECT id FROM categories WHERE slug = 'mechanical'), 'Vulcanizer', 'vulcanizer');

-- Masonry
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Masonry', 'masonry', 'masonry', 'Block laying, tiling, and concrete work', 11);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'masonry'), 'Block Laying', 'block-laying'),
  ((SELECT id FROM categories WHERE slug = 'masonry'), 'Tiling', 'tiling'),
  ((SELECT id FROM categories WHERE slug = 'masonry'), 'Plastering', 'plastering'),
  ((SELECT id FROM categories WHERE slug = 'masonry'), 'Concrete Work', 'concrete-work'),
  ((SELECT id FROM categories WHERE slug = 'masonry'), 'Interlocking', 'interlocking');

-- Welding & Metalwork
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Welding & Metalwork', 'welding-metalwork', 'welding', 'Metal fabrication, welding, and iron works', 12);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'welding-metalwork'), 'Gate Fabrication', 'gate-fabrication'),
  ((SELECT id FROM categories WHERE slug = 'welding-metalwork'), 'Burglar Proof', 'burglar-proof'),
  ((SELECT id FROM categories WHERE slug = 'welding-metalwork'), 'Stainless Steel Work', 'stainless-steel-work'),
  ((SELECT id FROM categories WHERE slug = 'welding-metalwork'), 'Aluminum Work', 'aluminum-work'),
  ((SELECT id FROM categories WHERE slug = 'welding-metalwork'), 'Iron Bending', 'iron-bending');

-- AC & Refrigeration
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('AC & Refrigeration', 'ac-refrigeration', 'ac', 'Air conditioning and refrigeration services', 13);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'ac-refrigeration'), 'AC Installation', 'ac-installation'),
  ((SELECT id FROM categories WHERE slug = 'ac-refrigeration'), 'AC Repair', 'ac-repair'),
  ((SELECT id FROM categories WHERE slug = 'ac-refrigeration'), 'AC Servicing', 'ac-servicing'),
  ((SELECT id FROM categories WHERE slug = 'ac-refrigeration'), 'Refrigerator Repair', 'refrigerator-repair'),
  ((SELECT id FROM categories WHERE slug = 'ac-refrigeration'), 'Freezer Repair', 'freezer-repair');

-- Interior Design
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Interior Design', 'interior-design', 'interior', 'Home and office interior decoration', 14);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'interior-design'), 'Home Decoration', 'home-decoration'),
  ((SELECT id FROM categories WHERE slug = 'interior-design'), 'Office Setup', 'office-setup'),
  ((SELECT id FROM categories WHERE slug = 'interior-design'), 'Curtain Installation', 'curtain-installation'),
  ((SELECT id FROM categories WHERE slug = 'interior-design'), 'Space Planning', 'space-planning');

-- Photography & Videography
INSERT INTO categories (name, slug, icon, description, sort_order) VALUES ('Photography & Videography', 'photography-videography', 'photography', 'Event and studio photography and video', 15);
INSERT INTO skills (category_id, name, slug) VALUES
  ((SELECT id FROM categories WHERE slug = 'photography-videography'), 'Event Photography', 'event-photography'),
  ((SELECT id FROM categories WHERE slug = 'photography-videography'), 'Studio Photography', 'studio-photography'),
  ((SELECT id FROM categories WHERE slug = 'photography-videography'), 'Wedding Photography', 'wedding-photography'),
  ((SELECT id FROM categories WHERE slug = 'photography-videography'), 'Video Production', 'video-production'),
  ((SELECT id FROM categories WHERE slug = 'photography-videography'), 'Drone Photography', 'drone-photography');

-- ===========================================
-- SYSTEM SETTINGS
-- ===========================================
INSERT INTO system_settings (key, value, description) VALUES
  ('commission_rate', '0.15', 'Platform commission rate (15%)'),
  ('grace_period_days', '3', 'Subscription grace period in days'),
  ('max_strikes', '3', 'Maximum strikes before auto-ban'),
  ('job_expiry_days', '30', 'Default job expiry in days'),
  ('min_budget', '500', 'Minimum job budget in Naira'),
  ('min_withdrawal', '5000', 'Minimum payout withdrawal in Naira'),
  ('review_window_days', '7', 'Days after completion to leave a review'),
  ('max_portfolio_images', '10', 'Maximum portfolio images per worker'),
  ('app_name', '"Artisan Marketplace"', 'Application name'),
  ('support_email', '"support@artisanmarketplace.ng"', 'Support email address'),
  ('support_phone', '"+2348000000000"', 'Support phone number');
