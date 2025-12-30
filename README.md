<!-- CarbonFlux README (HTML) -->

<h1>CarbonFlux</h1>
<p><strong>Analyzing ecosystem flux responses to extreme climate events using AmeriFlux data</strong></p>

<hr>
<h2>TLDR</h2>
<p>
  <strong>CarbonFlux</strong> uses <strong>machine learning</strong> and </strong>explainable AI</strong> to determine environmental 
  drivers of anomalously large movements of carbon into or out of an ecosystem. </strong>Random forest</strong> was 
  applied to data from 14 weather tower stations (AmeriFlux network), and trends and patterns in 
  biogeochemical responses to weather events were identified using </strong>SHAP analysis</strong>. I determined 
  that the current global trend towards patterns of infrequent, but large rain events is a key
  driver of anomalous carbon movement. Biogeochemical anomalies were affected by environmental
  conditions ranging up to a year in the past, and the impacts of many of these conditions (like light
  input and temperature) varied by ecosystem type and climate. These findings help us understand 
  how our biogeochemical cycle---and the health of ecosystem---may change under trends in weather and 
  environmental conditions, as well as help us understand our current and future carbon balance.
</p>

<h2> Highlights</h2>
<ul>
  <li><strong>AmeriFlux and Satellite Data Integration</strong>: downloaded and curated site-by-site</li>
  <li><strong>Extreme Event Detection</strong>: identified anomalous fluxes using a </strong>quantile spline regression approach</strong></li>
  <li><strong>Machine Learning</strong>: random forest classifiers, SHAP analysis, quadratic regression</li>
  <li><strong>Data Visualization</strong>: trends in environmental drivers across seasons, climates, and ecosystems</li>
  <li><strong>HPC Workflow</strong>: parallel processing for scalable analysis</li>
</ul>

<h2>Data Visualization</h2>
<p>
  <!-- Replace the src path with your actual image -->
  <img src="images/extremeflux_viz.png" alt="Seasonal flux response under varying MAT categories" width="800🛠 Tech Stack</h2>
<ul>
  <li><strong>Languages</strong>: R </li>
  <li><strong>Libraries</strong>: ggplot2, pandas </li>
  <li><strong>Compute</strong>: HPC cluster for large-scale processing</li>
  <li><strong>Data Source</strong>: <a href="https://ameriflux.lbl.govx Network</a></li>
</ul>

<h2>Why this project?</h2>
<p>
  Extreme carbon flux contribute an excess amount to the annual carbon balance globally. Understanding the controls of extreme fluxes
  is critical for predicting <strong>carbon cycle feedbacks</strong> and <strong>climate resilience</strong>. CarbonFlux provides a scalable framework
  to analyze these dynamics across diverse ecosystems and climates, and draws actionable insights on weather patterns driving
  extremes across various ecosystems.
</p>

<h2>Workflow Overview</h2>
<pre>
carbonflux/
├── data_processing/        # Data cleaning and extreme identification
├── analysis/               # HPC job submission files for ML
├── functions/              # Key functions for data preprocessing 
├── figures/                # Figures for README and publication
├── communication/          # Posters and presentations for communication
├── visualizations.RMD      # Example code for key figures
└── README.md
</pre>

<h2>Products and Communication</h2>
<ul>
  <li><strong>Peer-Reviewed Publication</strong>: In revision, stay tuned!</li>
  <li><strong>AmeriFlux 2025 Annual Meeting Poster</strong>: 
    <img src="https://github.com/marleeyork-pf/CarbonFlux/blob/main/communication/AmeriFluxPoster.pdf" alt="AmeriFlux 2025 Poster" width="400">
  </li>
  <li><strong>Biennial Conference of Science and Management Speaker Presentation</strong>: 
     <img src="https://github.com/marleeyork-pf/CarbonFlux/blob/main/communication/Presentation_Biennial.pdf" alt="Biennial 2025 Presentation" width="400">
  </li>
   <li><strong>Python for Ecologist Workshop Leader</strong>: used this data to train ecologist in Matplotlib and seaborn</li>
  <li><strong>American Geophysical Union 2024 Poster</strong>: 
    <img src="https://github.com/marleeyork-pf/CarbonFlux/blob/main/communication/AmeriFluxPoster.pdf" alt="AGU 2024 Poster" width="400">
  </li>
</ul>

<h2>🔗 Links</h2>
<ul>
  <!-- Replace with your actual URLs if you have them -->
  <li><a href="https://ameriflux.lbl.gov/" target="_blank" rel="noopener="https://your-username.github.io/extremeflux/" target="_blank"tHub Pages)</a></li>
</ul>

<h2>📬 Contact</h2>
<p>
  For questions or collaboration: <strong>marleeyork2025@gmail.com</strong><br>
<p>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue.svg="badge/status-research--prototype-purple.svg
</p>
