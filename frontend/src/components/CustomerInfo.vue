<template>
    <div class="mb-2 flex gap-3">
      <span>Name: <b>{{ customer.first_name }} {{ customer.last_name }}</b></span>
      <span>Address: <b>{{ customer.address }}</b></span>
      <span>Mobile: <b>{{ customer.phone_number }}</b></span>
    </div>
  </template>
  
  <script setup>
  defineProps({
    customer: {
      type: Object,
      required: true,
    },
  });
  </script>
  