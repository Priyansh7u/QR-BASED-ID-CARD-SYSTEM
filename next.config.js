/** @type {import('next').NextConfig} */
module.exports = {
  experimental: {
    // allow photo uploads up to 5 MB through the admin forms
    serverActions: { bodySizeLimit: '5mb' },
  },
};
