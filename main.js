let chart;
let currentSensorId = document.getElementById("sensorId").value;
let lastDataJSON = ""; // Guarda la última respuesta para comparar

async function loadData() {
    if (!currentSensorId) return;

    const url = `https://hermes-client.vercel.app/api/sensor/data/${currentSensorId}?limit=50`;
    const response = await fetch(url);
    const json = await response.json();

    if (!json.data) return;

    // Convertimos a string para comparar fácilmente con la respuesta anterior
    const currentDataJSON = JSON.stringify(json.data);

    // Si la data no cambió, no hacemos nada
    if (currentDataJSON === lastDataJSON) {
        return;
    }

    // Actualizamos el registro de la última data
    lastDataJSON = currentDataJSON;

    // Invertir para que lo más reciente esté a la derecha
    const data = json.data.reverse();

    const labels = data.map(item => new Date(item.createdAt).toLocaleTimeString());
    const values = data.map(item => item.value);

    if (!chart) {
        chart = new Chart(document.getElementById("myChart"), {
            type: "line",
            data: {
                labels: labels,
                datasets: [{
                    label: "Sensor",
                    data: values,
                    borderColor: "cyan",
                    backgroundColor: "rgba(0,255,255,0.2)",
                    fill: true,
                    tension: 0.3
                }]
            },
            options: {
                responsive: true,
                plugins: { legend: { labels: { color: "white" } } },
                scales: {
                    x: { ticks: { color: "white" } },
                    y: { ticks: { color: "white" } }
                }
            }
        });
    } else {
        chart.data.labels = labels;
        chart.data.datasets[0].data = values;
        chart.update();
    }
}

function updateSensor() {
    currentSensorId = document.getElementById("sensorId").value;
    lastDataJSON = ""; // reinicia comparación al cambiar sensor
    if (chart) {
        chart.destroy();
        chart = null;
    }
    loadData();
}

// Auto refresco cada 400 ms
setInterval(loadData, 400);

// Carga inicial
loadData();
