import { useEffect, useState } from "react";

type Location = {
  id: number;
  name: string;
  lat: number;
  lng: number;
};

function App() {
  const [locations, setLocations] = useState<Location[]>([]);

  useEffect(() => {
    fetch("/api/locations")
      .then(res => res.json())
      .then(data => setLocations(data));
  }, []);

  return (
    <div style={{ padding: "2rem" }}>
      <h1>DevOps Demo</h1>

      <ul>
        {locations.map(loc => (
          <li key={loc.id}>
            {loc.name} ({loc.lat}, {loc.lng})
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
