<template>
  <div class="container mx-auto p-4">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Appointment Reports (Daily Series)</h1>
      <div>
        <label for="period-filter" class="mr-2 text-sm font-medium text-gray-700">Filter by Period:</label>
        <select 
          id="period-filter"
          v-model="selectedPeriod"
          @change="handlePeriodChange"
          class="select select-bordered select-sm"
        >
          <option value="last_7_days">Last 7 Days</option>
          <option value="last_30_days">Last 30 Days</option>
          <option value="last_90_days">Last 90 Days</option>
          <option value="last_365_days">Last 365 Days</option>
        </select>
      </div>
    </div>

    <!-- Appointments by Category Chart -->
    <section class="mb-8 p-6 bg-white shadow-lg rounded-lg">
      <h2 class="text-xl font-semibold mb-4">Appointments by Category</h2>
      <div v-if="reportStore.isLoadingByCategory" class="text-center py-8">
        <div class="loading loading-spinner loading-lg"></div>
        <p class="mt-2">Loading category data...</p>
      </div>
      <div v-else-if="reportStore.errorByCategory" class="alert alert-error">
        {{ reportStore.errorByCategory }}
      </div>
      <div v-else-if="categoryChartData.datasets && categoryChartData.datasets.length > 0">
        <Line :data="categoryChartData" :options="chartOptions('Daily Appointments by Category')" style="height: 400px;" />
      </div>
      <div v-else class="text-center py-8">
        <p>No data available for appointments by category for the selected period.</p>
      </div>
    </section>

    <!-- Appointments by Age Chart -->
    <section class="mb-8 p-6 bg-white shadow-lg rounded-lg">
      <h2 class="text-xl font-semibold mb-4">Appointments by Age Group</h2>
      <div v-if="reportStore.isLoadingByAge" class="text-center py-8">
        <div class="loading loading-spinner loading-lg"></div>
        <p class="mt-2">Loading age data...</p>
      </div>
      <div v-else-if="reportStore.errorByAge" class="alert alert-error">
        {{ reportStore.errorByAge }}
      </div>
      <div v-else-if="ageChartData.datasets && ageChartData.datasets.length > 0">
        <Line :data="ageChartData" :options="chartOptions('Daily Appointments by Age Group')" style="height: 400px;" />
      </div>
      <div v-else class="text-center py-8">
        <p>No data available for appointments by age for the selected period.</p>
      </div>
    </section>

    <!-- Appointments by Department Chart -->
    <section class="p-6 bg-white shadow-lg rounded-lg">
      <h2 class="text-xl font-semibold mb-4">Appointments by Department</h2>
      <div v-if="reportStore.isLoadingByDepartment" class="text-center py-8">
        <div class="loading loading-spinner loading-lg"></div>
        <p class="mt-2">Loading department data...</p>
      </div>
      <div v-else-if="reportStore.errorByDepartment" class="alert alert-error">
        {{ reportStore.errorByDepartment }}
      </div>
      <div v-else-if="departmentChartData.datasets && departmentChartData.datasets.length > 0">
        <Line :data="departmentChartData" :options="chartOptions('Daily Appointments by Department')" style="height: 400px;" />
      </div>
      <div v-else class="text-center py-8">
        <p>No data available for appointments by department for the selected period.</p>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useReportStore } from '@/stores/reportStore';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
  TimeSeriesScale
} from 'chart.js';
import 'chartjs-adapter-date-fns';
import { Line } from 'vue-chartjs';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale, 
  TimeSeriesScale
);

const reportStore = useReportStore();
const selectedPeriod = ref('last_30_days');

const chartOptions = (titleText) => ({
  responsive: true,
  maintainAspectRatio: false,
  scales: {
    x: {
      type: 'time',
      time: {
        unit: 'day',
        tooltipFormat: 'MMM dd, yyyy',
        displayFormats: {
          day: 'MMM dd'
        }
      },
      title: {
        display: true,
        text: 'Date'
      },
      grid: {
        display: false
      }
    },
    y: {
      beginAtZero: true,
      title: {
        display: true,
        text: 'Number of Appointments'
      }
    },
  },
  plugins: {
    legend: {
      position: 'top',
    },
    title: {
      display: true,
      text: titleText,
    },
    tooltip: {
      mode: 'index',
      intersect: false,
    }
  },
  elements: {
    line: {
      tension: 0.4
    },
    point: {
      radius: 3
    }
  }
});

const getRandomColor = () => {
  const r = Math.floor(Math.random() * 200);
  const g = Math.floor(Math.random() * 200);
  const b = Math.floor(Math.random() * 200);
  return `rgba(${r}, ${g}, ${b}, 0.9)`;
};

const processDataForChart = (data, dateField, seriesField, countField) => {
  if (!data || data.length === 0) return { datasets: [] };

  const uniqueSeriesNames = [...new Set(data.map(item => item[seriesField]))].sort();
  
  const datasets = uniqueSeriesNames.map(name => {
    const color = getRandomColor();
    const seriesRawData = data
      .filter(d => d[seriesField] === name)
      .sort((a,b) => new Date(a[dateField]) - new Date(b[dateField]));

    const seriesChartData = seriesRawData.map(item => ({
      x: item[dateField],
      y: item[countField]
    }));

    return {
      label: name || 'N/A',
      data: seriesChartData,
      borderColor: color,
      backgroundColor: color.replace('0.9', '0.2'),
      tension: 0.1,
      fill: false, 
    };
  });
  return { datasets }; 
};

const categoryChartData = computed(() => {
  return processDataForChart(reportStore.appointmentsByCategory, 'day', 'category_title', 'count');
});

const ageChartData = computed(() => {
  return processDataForChart(reportStore.appointmentsByAge, 'day', 'age_group', 'count');
});

const departmentChartData = computed(() => {
  return processDataForChart(reportStore.appointmentsByDepartment, 'day', 'department', 'count');
});

const fetchDataForPeriod = async (period) => {
  await Promise.allSettled([
    reportStore.fetchAppointmentsByCategoryDaily({ period }),
    reportStore.fetchAppointmentsByAgeDaily({ period }),
    reportStore.fetchAppointmentsByDepartmentDaily({ period }),
  ]);
};

onMounted(() => {
  fetchDataForPeriod(selectedPeriod.value);
});

const handlePeriodChange = () => {
  fetchDataForPeriod(selectedPeriod.value);
};

</script>

<style scoped>
/* Ensure chart containers have a defined height if maintainAspectRatio is false */
/* Handled by inline style on <Line> components for now */
</style> 