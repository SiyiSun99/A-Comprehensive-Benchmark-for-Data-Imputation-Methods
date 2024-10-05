from sklearn.preprocessing import MinMaxScaler
import numpy as np
import pandas as pd
import tensorflow as tf
import MIDASpy as md
from tqdm import tqdm
import os

mechanism = ['MCAR','MAR','MNAR']
ratio = ['10','30','50']
sampletime = 10
case_num = 14
EPOCHS = 30
multiple_m = 5 # generate m completed dataset

for m in tqdm(mechanism):
    ma_folder = '/data/coml-data-imputation/shug7754/data_stored/data_midas/{mach}'.format(mach=m)
    if not os.path.exists(ma_folder):
        os.mkdir(ma_folder)
    case_folder = '/data/coml-data-imputation/shug7754/data_stored/data_midas/{mach}/Case{cs_num}'.format(mach=m, cs_num = case_num)
    if not os.path.exists(case_folder):
        os.mkdir(case_folder)
    for r in tqdm(ratio):
        ratio_folder = '/data/coml-data-imputation/shug7754/data_stored/data_midas/{mach}/Case{cs_num}/miss{rt}'.format(mach=m, cs_num = case_num, rt = r)
        if not os.path.exists(ratio_folder):
            os.mkdir(ratio_folder)

        for i in tqdm(range(sampletime)):
            file_url = '/data/coml-data-imputation/shug7754/data_stored/data_miss/{mach}/Case{cs_num}/miss{rt}/{n}.csv'.format(mach=m, cs_num = case_num, rt = r, n = i)
            data_0 = pd.read_csv(file_url)
            initial_col_order = data_0.columns

            categorical = [c for c in data_0.columns if c.startswith('cat')]
            data_cat, cat_cols_list = md.cat_conv(data_0[categorical])

            data_0.drop(categorical, axis = 1, inplace = True)
            constructor_list = [data_0]
            constructor_list.append(data_cat)
            data_in = pd.concat(constructor_list, axis=1)
            na_loc = data_in.isnull()
            data_in[na_loc] = np.nan

            imputer = md.Midas(layer_structure = [128,128,128], vae_layer = False, seed = 89, input_drop = 0.75)
            imputer.build_model(data_in, softmax_columns = cat_cols_list)
            imputer.train_model(training_epochs = 30)

            imputations = imputer.generate_samples(m=multiple_m).output_list 
            # combine datasets
            conbine_im = pd.concat(imputations)
            final_imputation = conbine_im.groupby(conbine_im.index).mean()
    
            flat_cats = [cat for variable in cat_cols_list for cat in variable]
            tmp_cat = []
            for c in range(len(categorical)):
                start = len(categorical[c]) + 1 # with '_'
                tmp_cat.append(final_imputation[cat_cols_list[c]].idxmax(axis=1).apply(lambda x:str(x)[start:]))        
            
            cat_df = pd.DataFrame({categorical[c_col]:tmp_cat[c_col] for c_col in range(len(categorical))})
            imputation = pd.concat([final_imputation, cat_df], axis = 1).drop(flat_cats, axis = 1)
            imputation = imputation[initial_col_order]
            
            save_url = '/data/coml-data-imputation/shug7754/data_stored/data_midas/{mach}/Case{cs_num}/miss{rt}/{n}.csv'.format(mach=m, cs_num = case_num, rt = r, n = i)
            imputation.to_csv(save_url, index = False)
