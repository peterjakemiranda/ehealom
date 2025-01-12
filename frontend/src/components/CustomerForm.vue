<template>
  <form @submit.prevent="onSubmit" class="card bg-white p-4">
    <div class="grid grid-cols-2 gap-4">
      <div class="form-control">
        <label for="first_name" class="label">
          <span class="label-text text-gray-700">First Name</span>
        </label>
        <input
          v-model="formData.first_name"
          type="text"
          id="first_name"
          class="input input-bordered bg-gray-50"
          required
        />
      </div>

      <div class="form-control">
        <label for="last_name" class="label">
          <span class="label-text text-gray-700">Last Name</span>
        </label>
        <input
          v-model="formData.last_name"
          type="text"
          id="last_name"
          class="input input-bordered bg-gray-50"
          required
        />
      </div>
    </div>

    <div class="form-control mb-2">
      <label for="address" class="label">
        <span class="label-text text-gray-700">Address</span>
      </label>
      <input
        v-model="formData.address"
        type="text"
        id="address"
        class="input input-bordered bg-gray-50"
        required
      />
    </div>

    <div class="form-control mb-2">
      <label for="phone_number" class="label">
        <span class="label-text text-gray-700">Phone Number</span>
      </label>
      <input
        v-model="formData.phone_number"
        type="tel"
        id="phone_number"
        class="input input-bordered bg-gray-50"
      />
    </div>

    <div class="form-control mb-2">
      <label for="remarks" class="label">
        <span class="label-text text-gray-700">Remarks</span>
      </label>
      <input
        v-model="formData.remarks"
        type="text"
        id="remarks"
        class="input input-bordered bg-gray-50"
        placeholder="Enter any additional information about the customer"
      />
    </div>

    <div class="grid grid-cols-2 gap-4">
      <div class="form-control mb-2">
        <label for="id_type" class="label">
          <span class="label-text text-gray-700">ID Type</span>
        </label>
        <select
          v-model="formData.id_type"
          id="id_type"
          class="select select-bordered bg-gray-50"
        >
          <option value="">Select ID type</option>
          <option value="passport">Passport</option>
          <option value="drivers_license">Driver's License</option>
          <option value="national_id">National ID</option>
        </select>
      </div>

      <div class="form-control mb-2">
        <label for="id_number" class="label">
          <span class="label-text text-gray-700">ID Number</span>
        </label>
        <input
          v-model="formData.id_number"
          type="text"
          id="id_number"
          class="input input-bordered bg-gray-50"
        />
      </div>
    </div>

    <div class="mt-6 flex gap-4">
      <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
        Cancel
      </button>
      <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading">
        {{ props.customer?.uuid ? 'Update' : 'Create' }} Customer
      </button>
    </div>
  </form>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useCustomerStore } from '@/stores/customerStore'
import { swalHelper } from '@/utils/swalHelper'

const props = defineProps({
  customer: {
    type: Object,
    required: false,
    default: () => ({})
  }
})

const emit = defineEmits(['saved', 'cancel'])
const isLoading = ref(false)
const customerStore = useCustomerStore()

const formData = ref({
  uuid: props.customer?.uuid || crypto.randomUUID(),
  localId: props.customer?.localId || Date.now(),
  first_name: props.customer?.first_name || '',
  last_name: props.customer?.last_name || '',
  address: props.customer?.address || '',
  phone_number: props.customer?.phone_number || '',
  email: props.customer?.email || '',
  id_type: props.customer?.id_type || '',
  id_number: props.customer?.id_number || '',
  preferred_communication_channel: props.customer?.preferred_communication_channel || 'mobile',
  remarks: props.customer?.remarks || '',
  sync_status: 'pending',
  created_at: props.customer?.created_at || new Date().toISOString(),
  updated_at: new Date().toISOString()
})

watch(() => props.customer, (newVal) => {
  formData.value = {
    ...formData.value,
    ...newVal,
    uuid: formData.value.uuid,
    localId: formData.value.localId,
    sync_status: 'pending',
    updated_at: new Date().toISOString()
  }
}, { deep: true })

async function onSubmit() {
  const isEdit = !!props.customer?.uuid
  try {
    isLoading.value = true
    const savedCustomer = isEdit
      ? await customerStore.updateCustomer(formData.value.uuid, formData.value)
      : await customerStore.addCustomer(formData.value)
    
    swalHelper.toast('success', `Customer ${isEdit ? 'updated' : 'added'} successfully`)
    emit('saved', savedCustomer)
  } catch (error) {
    console.error('Customer save error:', error)
    swalHelper.toast('error', `Failed to ${isEdit ? 'update' : 'add'} customer`)
  } finally {
    isLoading.value = false
  }
}
</script>