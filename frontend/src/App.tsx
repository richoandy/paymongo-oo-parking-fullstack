import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Layout } from './components/Layout';
import { Home } from './pages/Home';
import { LotView } from './pages/LotView';

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/lot/:id" element={<LotView />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}

export default App;
