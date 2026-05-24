# PIE-FCCS Analysis Scripts

MATLAB scripts for processing and analyzing pulsed interleaved excitation fluorescence cross-correlation spectroscopy (PIE-FCCS) data acquired from time-correlated single-photon counting (TCSPC) experiments.

This repository contains scripts for converting PicoQuant `.pt3`/`.ptu` files into MATLAB-compatible photon-arrival files, generating binned intensity traces, calculating autocorrelation and cross-correlation curves, averaging sub-acquisitions, fitting 2D and 3D diffusion models, and extracting fluorescence lifetime/microtime information for PIE gating and quality control.

## Overview

The analysis workflow is intended for live-cell or solution-based PIE-FCCS experiments using two detection channels, typically a green and a red fluorescence channel. The scripts support analysis of:

- Green-channel autocorrelation
- Red-channel autocorrelation
- Red-green cross-correlation
- Multi-tau correlation analysis
- Sub-acquisition averaging
- 2D diffusion fitting
- 3D diffusion fitting
- Triplet/dark-state fitting of autocorrelation curves
- Counts-per-second calculation
- Fluorescence microtime/lifetime inspection for PIE gate selection

## Typical Workflow

```text
Raw TCSPC files
.pt3 or .ptu
        |
        v
ptu2mat.m
Convert TCSPC files into MATLAB .mat files
        |
        v
ptum2Ft_divACQs2.m
Generate binned photon-count traces and optional sub-acquisitions
        |
        v
HXCor_R.m / HXCor_G.m / HXCor_X.m
Calculate red ACF, green ACF, and red-green CCF
        |
        v
PQ_avg_graphs2_pm_ColorChoices.m
Average sub-acquisitions and generate *_CorrQ.dat and *_IntH.dat files
        |
        v
Diffusion_2Dtrip_lsqnl_fit_nonTccf_Norm.m
Fit ACF/CCF curves and export diffusion/correlation parameters
        |
        v
Diffusion_3Dtrip_lsqnl_Kconstant_fit_NormV2.m
Fit ACF/CCF curves and export diffusion/correlation parameters
